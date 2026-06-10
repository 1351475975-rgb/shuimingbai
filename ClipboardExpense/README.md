# 剪贴板记账 iOS 原生 App

## 功能

- 剪贴板提示 + 粘贴记账
- 手动记账 / 分类管理 / 日周月统计
- **半自动：快捷指令 + App Intent**（付完通知 → 自动打开确认页）
- 解析：支付宝/微信/银行/美团/账单详情/支付成功通知

## 编译（需 Mac 或云 Mac）

```bash
open ClipboardExpense.xcodeproj
```

设置 Signing Team → 真机 Run。

## 半自动记账测试流程

### A. 快捷指令手动测（不需自动化）

1. 安装 App 到 iPhone
2. 打开 **快捷指令** → + → 添加 **从通知记账**
3. 「支付文本」填入样例：
   ```
   你向杭州余杭区良渚陈素红副食品店付款14.00元
   ```
4. 运行 → App 应打开并弹出 **确认记账**

### B. 通知自动化（完整半自动）

1. App 内 **自动记账** Tab 按步骤配置
2. 微信/支付宝各建一条「收到通知 → 从通知记账」
3. 付一笔小额 → 应自动打开确认页 → 点 **保存**

### C. 剪贴板备用

- **从剪贴板记账** Intent
- 或 App 内「粘贴记账」

## 单元测试

```bash
xcodebuild test -project ClipboardExpense.xcodeproj -scheme ClipboardExpense \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

## 无 Mac

见 [cloud-mac-ios-build.md](../docs/cloud-mac-ios-build.md)
