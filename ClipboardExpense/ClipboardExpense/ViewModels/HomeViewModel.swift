import Foundation
import Observation

@Observable
final class HomeViewModel {
    let clipboardMonitor = ClipboardMonitor()
    var pendingParsedPayment: ParsedPayment?
    var showConfirmSheet = false
    var parseErrorMessage: String?

    func handleBecomeActive() {
        clipboardMonitor.checkOnBecomeActive()
    }

    func pasteFromClipboard() {
        parseErrorMessage = nil
        guard let text = clipboardMonitor.readClipboardText(), !text.isEmpty else {
            parseErrorMessage = "剪贴板为空或无法读取"
            return
        }
        processText(text)
    }

    func processText(_ text: String) {
        parseErrorMessage = nil
        guard let parsed = PaymentParser.parse(text) else {
            parseErrorMessage = "未能识别支付信息，请手动编辑"
            pendingParsedPayment = ParsedPayment(
                amount: 0,
                merchant: nil,
                category: "其他",
                time: .now,
                source: .manual,
                confidence: .low,
                rawText: text
            )
            showConfirmSheet = true
            clipboardMonitor.dismissPrompt()
            return
        }
        pendingParsedPayment = parsed
        showConfirmSheet = true
        clipboardMonitor.dismissPrompt()
    }

    func resetConfirmState() {
        pendingParsedPayment = nil
        showConfirmSheet = false
    }
}
