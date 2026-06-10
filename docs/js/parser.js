/**
 * 支付文本解析引擎 — 与 iOS PaymentParser.swift 规则对齐
 */
const MERCHANT_CATEGORY_MAP = {
  麦当劳: '餐饮',
  肯德基: '餐饮',
  星巴克: '餐饮',
  全家: '餐饮',
  便利店: '购物',
  滴滴: '交通',
  美团: '餐饮',
  外卖: '餐饮',
};

const RULES = [
  {
    source: 'alipay',
    pattern: /(?:支付宝).*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)/,
    confidence: 'high',
  },
  {
    source: 'wechat',
    pattern: /微信支付.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)/,
    confidence: 'high',
  },
  {
    source: 'bank',
    pattern: /消费(\d+(?:\.\d{1,2})?)元\s*(.+)/,
    confidence: 'high',
  },
  {
    source: 'meituan',
    pattern: /美团.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)/,
    confidence: 'high',
  },
  {
    source: 'jd',
    pattern: /京东.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)/,
    confidence: 'medium',
  },
  {
    source: 'pinduoduo',
    pattern: /拼多多.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)/,
    confidence: 'medium',
  },
];

const GENERIC_PATTERNS = [
  /[¥￥]\s*(\d+(?:\.\d{1,2})?)/,
  /(\d+(?:\.\d{1,2})?)\s*元/,
];

const SOURCE_LABELS = {
  alipay: '支付宝',
  wechat: '微信支付',
  bank: '银行',
  meituan: '美团',
  jd: '京东',
  pinduoduo: '拼多多',
  generic: '通用',
  manual: '手动',
};

function categorize(merchant, text) {
  const candidates = [merchant, text].filter(Boolean);
  for (const candidate of candidates) {
    for (const [keyword, category] of Object.entries(MERCHANT_CATEGORY_MAP)) {
      if (candidate.includes(keyword)) return category;
    }
  }
  return '其他';
}

function extractTime(text) {
  const patterns = [
    /(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})/,
    /(\d{2})-(\d{2})\s+(\d{2}):(\d{2})/,
  ];
  const now = new Date();
  for (const pattern of patterns) {
    const m = text.match(pattern);
    if (!m) continue;
    if (m.length === 6) {
      return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]);
    }
    if (m.length === 5) {
      return new Date(now.getFullYear(), +m[1] - 1, +m[2], +m[3], +m[4]);
    }
  }
  return null;
}

function matchRule(rule, text) {
  const m = text.match(rule.pattern);
  if (!m) return null;
  const amount = parseFloat(m[1]);
  if (Number.isNaN(amount)) return null;
  const merchant = m[2]?.trim() || null;
  return {
    amount,
    merchant: merchant || null,
    category: categorize(merchant, text),
    time: extractTime(text) || new Date(),
    source: rule.source,
    confidence: rule.confidence,
    rawText: text,
  };
}

export function parsePayment(text) {
  const trimmed = (text || '').trim();
  if (!trimmed) return null;

  for (const rule of RULES) {
    const result = matchRule(rule, trimmed);
    if (result) return result;
  }

  for (const pattern of GENERIC_PATTERNS) {
    const m = trimmed.match(pattern);
    if (!m) continue;
    const amount = parseFloat(m[1]);
    if (Number.isNaN(amount)) continue;
    return {
      amount,
      merchant: null,
      category: categorize(null, trimmed),
      time: extractTime(trimmed) || new Date(),
      source: 'generic',
      confidence: 'low',
      rawText: trimmed,
    };
  }

  return null;
}

export function getSourceLabel(source) {
  return SOURCE_LABELS[source] || source;
}

export const PRESET_CATEGORIES = ['餐饮', '交通', '购物', '生活', '娱乐', '其他'];
