# 无 Mac 编译上架 iOS 原生 App 指南

适用于 [`ClipboardExpense`](../ClipboardExpense) Swift 工程。需要 **Apple 开发者账号** 和 **云端 Mac** 或 **CI**。

## 方案对比

| 方案 | 月费约 | 适合 |
|------|--------|------|
| MacinCloud / 云 Mac | ¥50–200 | 首次上架、真机调试 |
| GitHub Actions | 免费额度 | 自动化构建 |
| Codemagic | 有免费档 | 免维护 Mac |
| 借 Mac 1 天 | 0 | 只上架一次 |

建议：PWA 先用 → 注册开发者 → 云 Mac 签名上架 → 后续 GitHub Actions 自动打包。

## Apple 开发者账号

1. [developer.apple.com/programs](https://developer.apple.com/programs/) 注册并付费
2. 记录 Team ID

## MacinCloud 步骤

1. 租 macOS 14+ 远程 Mac，安装 Xcode
2. `git clone` 或上传 `ClipboardExpense` 目录
3. Xcode 打开工程 → Signing 选 Team → Bundle ID 改唯一
4. iPhone 连 Mac（或无线调试）→ Run 测剪贴板
5. Product → Archive → Distribute → App Store Connect
6. App Store Connect 填元数据，隐私说明写：**仅用户点击粘贴时读剪贴板**

## GitHub Actions

见 `.github/workflows/ios-build.yml`。Secrets 需证书、p12、Provisioning Profile、App Store Connect API Key（证书须在 Mac 上生成一次）。

## Codemagic

连接 GitHub → 选 iOS → 配置证书 → 构建并提交 App Store。

## 常见问题

- Windows 不能装 Xcode，必须 macOS
- PWA 与原生数据不互通（除非后续做云同步）
- 剪贴板审核：勿写「自动监控」，写「主动粘贴记账」

## 时间线

1. 今天：PWA 上 GitHub Pages，手机加主屏幕
2. 本周：开发者账号
3. 租云 Mac 1 天：签名 + Archive + 提交审核
