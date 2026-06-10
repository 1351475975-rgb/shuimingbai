/**
 * 在 Node 下快速验证解析器：node js/parser.test.mjs
 */
import { parsePayment } from './parser.js';

const samples = [
  ['支付宝', '支付宝-向商家付款 ￥18.50 全家便利店', 18.5],
  ['微信', '微信支付 消费 ￥32.00 麦当劳', 32],
  ['银行', '【招商银行】您尾号1234卡消费86.00元 星巴克', 86],
  ['美团', '美团支付 ￥25.00 外卖订单', 25],
  ['京东', '京东支付 ￥199.00 蓝牙耳机', 199],
  ['拼多多', '拼多多支付 ￥9.90 纸巾', 9.9],
  ['通用', '今天花了 ￥12.5 买咖啡', 12.5],
];

let failed = 0;
for (const [name, text, expected] of samples) {
  const r = parsePayment(text);
  if (!r || r.amount !== expected) {
    console.error(`FAIL ${name}:`, r);
    failed++;
  } else {
    console.log(`OK ${name}: ¥${r.amount} ${r.merchant || ''}`);
  }
}
process.exit(failed ? 1 : 0);
