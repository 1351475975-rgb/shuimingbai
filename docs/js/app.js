import { parsePayment } from './parser.js';
import {
  addRecord,
  deleteRecord,
  getRecords,
  getCategories,
  addCategory,
  deleteCategory,
  calcStats,
  groupByDay,
} from './storage.js';
import { readClipboardText, setupVisibilityHint } from './clipboard.js';
import { initPopup, showConfirm, hideConfirm } from './popup.js';

const fmtMoney = (n) =>
  `¥${Number(n).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

const fmtTime = (iso) => {
  const d = new Date(iso);
  return d.toLocaleString('zh-CN', { hour: '2-digit', minute: '2-digit' });
};

const fmtDay = (key) => {
  const [y, m, d] = key.split('-');
  return `${y}年${m}月${d}日`;
};

let currentTab = 'home';
let showClipboardBanner = false;

function render() {
  renderStats();
  renderRecords();
  renderCategories();
  switchTabUI();
}

function renderStats() {
  const records = getRecords();
  const stats = calcStats(records);
  document.getElementById('stat-today').textContent = fmtMoney(stats.today.total);
  document.getElementById('stat-today-count').textContent = `${stats.today.count} 笔`;
  document.getElementById('stat-week').textContent = fmtMoney(stats.week.total);
  document.getElementById('stat-week-count').textContent = `${stats.week.count} 笔`;
  document.getElementById('stat-month').textContent = fmtMoney(stats.month.total);
  document.getElementById('stat-month-count').textContent = `${stats.month.count} 笔`;
}

function renderRecords() {
  const list = document.getElementById('record-list');
  const records = getRecords();
  if (!records.length) {
    list.innerHTML = `<div class="empty-state">
      <p>暂无账单</p>
      <p class="muted">复制支付文本后点「粘贴记账」</p>
    </div>`;
    return;
  }

  list.innerHTML = groupByDay(records)
    .map(
      ({ day, items }) => `
      <section class="day-group">
        <h3 class="day-label">${fmtDay(day)}</h3>
        ${items
          .map(
            (r) => `
          <article class="record-card" data-id="${r.id}">
            <div class="record-main">
              <strong>${r.merchant || r.category}</strong>
              <span class="record-amount">${fmtMoney(r.amount)}</span>
            </div>
            <div class="record-meta">
              <span class="tag">${r.category}</span>
              <span class="muted">${fmtTime(r.time)}</span>
            </div>
            <button type="button" class="btn-delete" data-delete="${r.id}" aria-label="删除">删除</button>
          </article>`
          )
          .join('')}
      </section>`
    )
    .join('');

  list.querySelectorAll('[data-delete]').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (confirm('删除这条记录？')) {
        deleteRecord(btn.dataset.delete);
        render();
      }
    });
  });
}

function renderCategories() {
  const list = document.getElementById('category-list');
  const categories = getCategories();
  list.innerHTML = categories
    .map(
      (c) => `
    <div class="category-row ${c.isPreset ? 'preset' : ''}">
      <span>${c.name}${c.isPreset ? ' <small class="muted">预设</small>' : ''}</span>
      ${!c.isPreset ? `<button type="button" class="btn-text" data-cat-del="${c.id}">删除</button>` : ''}
    </div>`
    )
    .join('');

  list.querySelectorAll('[data-cat-del]').forEach((btn) => {
    btn.addEventListener('click', () => {
      deleteCategory(btn.dataset.catDel);
      renderCategories();
    });
  });
}

function switchTabUI() {
  document.querySelectorAll('.tab-panel').forEach((el) => {
    el.hidden = el.dataset.tab !== currentTab;
  });
  document.querySelectorAll('.nav-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.tab === currentTab);
  });
  document.getElementById('paste-bar').hidden = currentTab !== 'home';
}

function processText(text) {
  const parsed = parsePayment(text);
  if (parsed) {
    showConfirm(parsed);
  } else {
    showConfirm({
      amount: '',
      merchant: '',
      category: '其他',
      time: new Date(),
      source: 'manual',
      confidence: 'low',
      rawText: text,
    });
  }
  hideClipboardBanner();
}

function isIOS() {
  return (
    /iPad|iPhone|iPod/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
  );
}

function openPasteSheet() {
  const overlay = document.getElementById('paste-overlay');
  const ta = document.getElementById('paste-textarea');
  ta.value = '';
  overlay.classList.add('open');
  setTimeout(() => ta.focus(), 100);
}

function closePasteSheet() {
  document.getElementById('paste-overlay')?.classList.remove('open');
}

async function pasteAndParse() {
  hideClipboardBanner();

  // iOS 主屏幕 PWA 经常拒绝 clipboard.readText，改用手动粘贴弹层
  if (isIOS()) {
    openPasteSheet();
    return;
  }

  try {
    const text = await readClipboardText();
    if (!text) {
      openPasteSheet();
      return;
    }
    processText(text);
  } catch {
    openPasteSheet();
  }
}

function hideClipboardBanner() {
  showClipboardBanner = false;
  document.getElementById('clipboard-banner').hidden = true;
}

function showClipboardBannerUI() {
  showClipboardBanner = true;
  document.getElementById('clipboard-banner').hidden = false;
}

function switchToTab(tab) {
  currentTab = tab;
  switchTabUI();
}

function onRecordSaved(record) {
  addRecord(record);
  render();
  switchToTab('home');
}

document.querySelectorAll('.nav-btn').forEach((btn) => {
  btn.addEventListener('click', () => switchToTab(btn.dataset.tab));
});

document.getElementById('btn-paste').addEventListener('click', pasteAndParse);
document.getElementById('banner-paste').addEventListener('click', pasteAndParse);
document.getElementById('banner-dismiss').addEventListener('click', hideClipboardBanner);

document.getElementById('paste-cancel').addEventListener('click', closePasteSheet);
document.getElementById('paste-parse').addEventListener('click', () => {
  const text = document.getElementById('paste-textarea').value.trim();
  if (!text) return;
  closePasteSheet();
  processText(text);
});
document.getElementById('paste-textarea').addEventListener('paste', () => {
  setTimeout(() => {
    const text = document.getElementById('paste-textarea').value.trim();
    if (text.length > 10) {
      closePasteSheet();
      processText(text);
    }
  }, 50);
});

document.getElementById('btn-parse-entry').addEventListener('click', () => {
  const text = document.getElementById('entry-text').value.trim();
  if (!text) return;
  processText(text);
});

document.getElementById('btn-manual-entry').addEventListener('click', () => {
  showConfirm({
    amount: '',
    merchant: '',
    category: '其他',
    time: new Date(),
    source: 'manual',
    confidence: 'high',
    rawText: '',
  });
});

document.getElementById('btn-add-category').addEventListener('click', () => {
  const input = document.getElementById('new-category');
  const name = input.value.trim();
  if (!name) return;
  addCategory(name);
  input.value = '';
  renderCategories();
});

initPopup(onRecordSaved);

setupVisibilityHint((hint) => {
  if (hint && currentTab === 'home') showClipboardBannerUI();
});

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js').catch(() => {});
}

render();
