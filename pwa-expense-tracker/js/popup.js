import { getSourceLabel } from './parser.js';
import { getCategories } from './storage.js';

let overlayEl;
let onSaveCallback;

export function initPopup(onSave) {
  onSaveCallback = onSave;
  overlayEl = document.getElementById('confirm-overlay');
  document.getElementById('confirm-cancel').addEventListener('click', hideConfirm);
  document.getElementById('confirm-save').addEventListener('click', saveConfirm);
}

export function showConfirm(parsed) {
  const categories = getCategories();
  const select = document.getElementById('confirm-category');
  select.innerHTML = categories
    .map((c) => `<option value="${c.name}">${c.name}</option>`)
    .join('');

  document.getElementById('confirm-amount').value = parsed.amount ?? '';
  document.getElementById('confirm-merchant').value = parsed.merchant || '';
  document.getElementById('confirm-category').value = parsed.category || '其他';
  document.getElementById('confirm-note').value = '';
  document.getElementById('confirm-time').value = formatLocalInput(parsed.time);
  document.getElementById('confirm-raw').textContent = parsed.rawText || '';
  document.getElementById('confirm-source').textContent = getSourceLabel(parsed.source);

  const warn = document.getElementById('confirm-warn');
  warn.hidden = parsed.confidence !== 'low';

  overlayEl.classList.add('open');
  overlayEl.dataset.rawText = parsed.rawText || '';
  overlayEl.dataset.source = parsed.source || 'manual';
}

export function hideConfirm() {
  overlayEl?.classList.remove('open');
}

function formatLocalInput(date) {
  const d = date instanceof Date ? date : new Date(date);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function saveConfirm() {
  const amount = parseFloat(document.getElementById('confirm-amount').value);
  if (!amount || amount <= 0) {
    alert('请输入有效金额');
    return;
  }
  const timeVal = document.getElementById('confirm-time').value;
  onSaveCallback({
    amount,
    merchant: document.getElementById('confirm-merchant').value.trim() || null,
    category: document.getElementById('confirm-category').value,
    note: document.getElementById('confirm-note').value.trim() || null,
    time: timeVal ? new Date(timeVal) : new Date(),
    source: overlayEl.dataset.source || 'manual',
    rawText: overlayEl.dataset.rawText || null,
  });
  hideConfirm();
}
