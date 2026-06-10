import AppIntents

struct ClipboardExpenseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseFromTextIntent(),
            phrases: [
                "用\(.applicationName)记账",
                "用\(.applicationName)记一笔",
                "\(.applicationName)从通知记账"
            ],
            shortTitle: "从通知记账",
            systemImageName: "bell.badge"
        )
        AppShortcut(
            intent: LogExpenseFromClipboardIntent(),
            phrases: [
                "用\(.applicationName)粘贴记账",
                "\(.applicationName)剪贴板记账"
            ],
            shortTitle: "剪贴板记账",
            systemImageName: "doc.on.clipboard"
        )
    }
}
