# 剪贴板记账 iOS App

原生 SwiftUI 记账 App：复制支付文本 → 切回 App → 提示/粘贴 → 解析确认 → 本地保存。

## 环境要求

- macOS + Xcode 15+
- iOS 17+（SwiftData）
- 真机测试剪贴板功能

## 打开项目

```bash
open ClipboardExpense.xcodeproj
```

在 Xcode 中设置 **Signing & Capabilities** 的 Development Team，选择 iPhone 模拟器或真机运行。

## 运行单元测试

```bash
xcodebuild test \
  -project ClipboardExpense.xcodeproj \
  -scheme ClipboardExpense \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

或在 Xcode 中 `Cmd+U` 运行 `PaymentParserTests`。

## 功能结构

| 模块 | 说明 |
|------|------|
| `PaymentParser` | 支付宝/微信/银行/美团/京东/拼多多/通用文本解析 |
| `ClipboardMonitor` | `changeCount` 检测剪贴板变化，用户点击后读取 |
| `HomeView` | 账单列表、日/周/月统计、粘贴记账 |
| `ManualEntryView` | 手动粘贴文本解析 |
| `CategoryManageView` | 预设 + 自定义分类 |
| `ConfirmExpenseSheet` | 解析结果确认与保存 |

## 真机验收清单

1. **支付宝样例**：复制 `支付宝-向商家付款 ￥18.50 全家便利店` → 切回 App → 顶部出现提示条 → 点击「粘贴记账」→ 确认金额/商家 → 保存
2. **微信样例**：复制 `微信支付 消费 ￥32.00 麦当劳` → 同样流程
3. **粘贴授权**：首次程序化读取剪贴板时 iOS 可能弹出粘贴授权，点「允许」
4. **离线持久化**：保存账单后杀进程重开，数据仍在首页列表
5. **手动记账**：「记账」Tab 粘贴文本 → 解析并记账
6. **分类管理**：「分类」Tab 添加自定义分类，确认页 Picker 可见
7. **统计**：首页今日/本周/本月金额随新账单更新
8. **删除**：账单列表左滑删除

## 测试样例文本

```
支付宝-向商家付款 ￥18.50 全家便利店
微信支付 消费 ￥32.00 麦当劳
【招商银行】您尾号1234卡消费86.00元 星巴克
美团支付 ￥25.00 外卖订单
京东支付 ￥199.00 蓝牙耳机
拼多多支付 ￥9.90 纸巾
今天花了 ￥12.5 买咖啡
```
