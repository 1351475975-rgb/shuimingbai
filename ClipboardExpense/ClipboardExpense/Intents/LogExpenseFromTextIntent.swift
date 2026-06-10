import AppIntents
import Foundation
import UIKit

/// 快捷指令 / 通知自动化调用：传入支付文本 → 解析 → 打开 App 确认页
struct LogExpenseFromTextIntent: AppIntent {
    static var title: LocalizedStringResource = "从通知记账"
    static var description = IntentDescription("解析微信/支付宝支付通知文本并打开确认页")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "支付文本", inputConnectionBehavior: .connectToPreviousIntentResult)
    var paymentText: String

    static var parameterSummary: some ParameterSummary {
        Summary("解析 \(\.$paymentText) 并记账")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.presentPaymentText(paymentText)
        return .result()
    }
}

/// 从剪贴板记账（背面轻点 / 小组件 / 手动运行快捷指令）
struct LogExpenseFromClipboardIntent: AppIntent {
    static var title: LocalizedStringResource = "从剪贴板记账"
    static var description = IntentDescription("读取剪贴板支付文本并打开确认页")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let text = UIPasteboard.general.string ?? ""
        AppState.shared.presentPaymentText(text)
        return .result()
    }
}
