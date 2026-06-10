import { PRESET_CATEGORIES } from './parser.js';

const RECORDS_KEY = 'clipboard-expense-records-v1';
const CATEGORIES_KEY = 'clipboard-expense-categories-v1';

function uid() {
  return crypto.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

export function getRecords() {
  try {
    const raw = localStorage.getItem(RECORDS_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

export function saveRecords(records) {
  localStorage.setItem(RECORDS_KEY, JSON.stringify(records));
}

export function addRecord(record) {
  const records = getRecords();
  records.unshift({
    id: uid(),
    amount: record.amount,
    category: record.category,
    note: record.note || null,
    merchant: record.merchant || null,
    time: record.time instanceof Date ? record.time.toISOString() : record.time,
    source: record.source || 'manual',
    rawText: record.rawText || null,
  });
  saveRecords(records);
  return records[0];
}

export function deleteRecord(id) {
  const records = getRecords().filter((r) => r.id !== id);
  saveRecords(records);
}

export function getCategories() {
  try {
    const raw = localStorage.getItem(CATEGORIES_KEY);
    if (raw) return JSON.parse(raw);
  } catch {
    /* ignore */
  }
  const defaults = PRESET_CATEGORIES.map((name, i) => ({
    id: `preset-${i}`,
    name,
    isPreset: true,
  }));
  localStorage.setItem(CATEGORIES_KEY, JSON.stringify(defaults));
  return defaults;
}

export function saveCategories(categories) {
  localStorage.setItem(CATEGORIES_KEY, JSON.stringify(categories));
}

export function addCategory(name) {
  const categories = getCategories();
  if (categories.some((c) => c.name === name)) return categories;
  categories.push({ id: uid(), name, isPreset: false });
  saveCategories(categories);
  return categories;
}

export function deleteCategory(id) {
  const all = getCategories();
  saveCategories(all.filter((c) => c.id !== id || c.isPreset));
  return getCategories();
}

export function calcStats(records) {
  const now = new Date();
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const dayOfWeek = now.getDay();
  const diffToMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  const startOfWeek = new Date(startOfDay);
  startOfWeek.setDate(startOfWeek.getDate() - diffToMonday);
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const sum = (list) => ({
    total: list.reduce((s, r) => s + Number(r.amount), 0),
    count: list.length,
  });

  const inRange = (r, start) => new Date(r.time) >= start;

  return {
    today: sum(records.filter((r) => inRange(r, startOfDay))),
    week: sum(records.filter((r) => inRange(r, startOfWeek))),
    month: sum(records.filter((r) => inRange(r, startOfMonth))),
  };
}

export function groupByDay(records) {
  const map = new Map();
  for (const r of records) {
    const d = new Date(r.time);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(r);
  }
  return [...map.entries()]
    .sort((a, b) => b[0].localeCompare(a[0]))
    .map(([day, items]) => ({
      day,
      items: items.sort((a, b) => new Date(b.time) - new Date(a.time)),
    }));
}
