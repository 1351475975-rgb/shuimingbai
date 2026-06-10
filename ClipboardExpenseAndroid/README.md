# 剪贴板记账 Android App

Kotlin + Jetpack Compose + Room。**Android Pro：通知栏监听微信/支付宝支付通知。**

## 功能

- 粘贴 / 剪贴板记账
- 手动记账、分类管理、日/周/月统计
- **NotificationListenerService**：付完款推送「检测到支付」→ 点击确认
- 解析规则与 iOS / PWA 对齐

## 环境

- Android Studio Hedgehog (2023.1+) 或更新
- JDK 17
- minSdk 26 / targetSdk 34

## 打开项目

1. Android Studio → Open → 选 `ClipboardExpenseAndroid`
2. 等待 Gradle Sync
3. 连接安卓手机（USB 调试）或模拟器
4. Run ▶

## 通知自动记账设置

1. 安装后打开 **自动** Tab
2. 点 **打开通知使用权设置** → 开启本 App
3. 确保微信/支付宝允许通知且显示预览
4. 小米/华为等：将 App 加入后台白名单
5. 付一笔小额 → 收到通知 → 点击 → 确认保存

## 单元测试

```bash
./gradlew test
```

## 打 Release APK

```bash
./gradlew assembleRelease
```

APK：`app/build/outputs/apk/release/`

## 项目结构

```
app/src/main/java/com/shuimingbai/clipboardexpense/
├── parser/PaymentParser.kt
├── service/PaymentNotificationListener.kt
├── data/ (Room)
├── ui/screens/
└── viewmodel/
```
