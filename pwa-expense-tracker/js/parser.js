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
  羊肉汤: '餐饮',
  饭店: '餐饮',
  餐厅: '餐饮',
  火锅: '餐饮',
  咖啡: '餐饮',
  奶茶: '餐饮',
  副食品: '购物',
  超市: '购物',
};

const BILL_CATEGORY_MAP = [
  [/餐饮|美食|下馆/, '餐饮'],
  [/购物|超市|副食|日用/, '购物'],
  [/交通|出行|打车|地铁/, '交通'],
  [/生活|缴费|充值/, '生活'],
  [/娱乐|游戏|电影/, '娱乐'],
];

function mapBillCategory(label) {
  if (!label) return null;
  for (const [pattern, cat] of BILL_CATEGORY_MAP) {
    if (pattern.test(label)) return cat;
  }
  return null;
}

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
  /(?:^|\n)\s*-(\d+(?:\.\d{1,2})?)\s*(?:\n|$)/m,
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

/** 支付成功通知类：消费金额 / 消费门店 / 消费时间 分行 */
function parseStructuredFields(text) {
  const amountMatch = text.match(/消费金额[:：]+\s*:?\s*(\d+(?:\.\d{1,2})?)\s*元?/);
  if (!amountMatch) return null;

  const amount = parseFloat(amountMatch[1]);
  if (Number.isNaN(amount)) return null;

  const merchantMatch = text.match(/消费门店[:：]+\s*:?\s*(.+?)(?:\r?\n|$)/);
  const merchant = merchantMatch?.[1]?.trim() || null;

  const timeMatch = text.match(
    /消费时间[:：]+\s*:?\s*(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2})/
  );
  let time = new Date();
  if (timeMatch) {
    time = new Date(
      +timeMatch[1],
      +timeMatch[2] - 1,
      +timeMatch[3],
      +timeMatch[4],
      +timeMatch[5]
    );
  } else {
    time = extractTime(text) || new Date();
  }

  let source = 'generic';
  if (text.includes('微信')) source = 'wechat';
  else if (text.includes('支付宝')) source = 'alipay';

  return {
    amount,
    merchant,
    category: categorize(merchant, text),
    time,
    source,
    confidence: merchant ? 'high' : 'medium',
    rawText: text,
  };
}

function extractTime(text) {
  const patterns = [
    [/支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2}):(\d{2})/, 'cnSec'],
    [/支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})/, 'isoSec'],
    [/支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})/, 'iso'],
    [/(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2}):(\d{2})/, 'cnSec'],
    [/(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2})/, 'cn'],
    [/(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})/, 'iso'],
    [/(\d{2})-(\d{2})\s+(\d{2}):(\d{2})/, 'md'],
  ];
  const now = new Date();
  for (const [pattern, kind] of patterns) {
    const m = text.match(pattern);
    if (!m) continue;
    if (kind === 'cnSec') {
      return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]);
    }
    if (kind === 'isoSec' || kind === 'iso') {
      return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], kind === 'isoSec' ? +m[6] : 0);
    }
    if (kind === 'cn') {
      return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]);
    }
    if (kind === 'md') {
      return new Date(now.getFullYear(), +m[1] - 1, +m[2], +m[3], +m[4]);
    }
  }
  return null;
}

/** 微信/支付宝账单详情页复制文本 */
function parseBillDetail(text) {
  const isBill =
    /账单详情|账单/.test(text) &&
    (/支付成功|交易成功/.test(text) || /支付时间/.test(text));
  if (!isBill) return null;

  const negAmount = text.match(/(?:^|\n)\s*-(\d+(?:\.\d{1,2})?)\s*(?:\n|$)/m);
  const posAmount = text.match(/消费金额[:：]+\s*:?\s*(\d+(?:\.\d{1,2})?)/);
  const amount = negAmount
    ? parseFloat(negAmount[1])
    : posAmount
      ? parseFloat(posAmount[1])
      : NaN;
  if (Number.isNaN(amount)) return null;

  let merchant =
    text.match(/商户全称[:：]\s*(.+?)(?:\r?\n|$)/)?.[1]?.trim() ||
    text.match(/商品[:：]\s*(.+?)(?:\r?\n|$)/)?.[1]?.trim()?.replace(/-消费$/, '') ||
    null;

  if (!merchant) {
    const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
    const billIdx = lines.findIndex((l) => l === '账单详情' || l === '账单');
    if (billIdx >= 0) {
      for (let i = billIdx + 1; i < Math.min(billIdx + 4, lines.length); i++) {
        const line = lines[i];
        if (/^-?\d+(\.\d+)?$/.test(line)) continue;
        if (/成功|失败|状态/.test(line)) continue;
        merchant = line.replace(/-消费$/, '');
        break;
      }
    }
  }

  const catLabel =
    text.match(/账单分类[:：]\s*(.+?)(?:\r?\n|$)/)?.[1]?.trim() ||
    text.match(/账单分类\s*\n\s*(.+?)(?:\r?\n|$)/)?.[1]?.trim();
  const category = mapBillCategory(catLabel) || categorize(merchant, text);

  let source = 'generic';
  if (/微信|零钱|收单机构.*建行|财付通/.test(text)) source = 'wechat';
  else if (/支付宝|余额宝|花呗/.test(text)) source = 'alipay';

  return {
    amount,
    merchant,
    category,
    time: extractTime(text) || new Date(),
    source,
    confidence: merchant ? 'high' : 'medium',
    rawText: text,
  };
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

  const structured = parseStructuredFields(trimmed);
  if (structured) return structured;

  const billDetail = parseBillDetail(trimmed);
  if (billDetail) return billDetail;

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
