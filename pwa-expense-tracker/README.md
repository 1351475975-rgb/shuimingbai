# 剪贴板记账 PWA

Windows 开发，iPhone 使用，无需 Mac。

## 本地预览

```powershell
cd pwa-expense-tracker
python -m http.server 8080
```

手机访问 `http://电脑局域网IP:8080`。剪贴板 API 需 HTTPS，本地 HTTP 可能受限，建议用 GitHub Pages。

## GitHub Pages 部署

1. Push 到 GitHub
2. Settings → Pages → 选 `main` 分支，目录 `/pwa-expense-tracker`
3. 打开 `https://用户名.github.io/仓库名/`
4. iPhone Safari → 分享 → **添加到主屏幕**

## 使用

复制支付文本 → 打开 App → **粘贴记账** → 确认保存。

## 图标

```powershell
.\scripts\generate-icons.ps1
```

## 原生 App

见 [cloud-mac-ios-build.md](../docs/cloud-mac-ios-build.md)。
