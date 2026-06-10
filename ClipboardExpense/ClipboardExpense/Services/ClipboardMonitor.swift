import UIKit
import Observation

@Observable
final class ClipboardMonitor {
    private(set) var hasPendingPaymentText = false
    private var lastChangeCount = UIPasteboard.general.changeCount

    func checkOnBecomeActive() {
        let pasteboard = UIPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        hasPendingPaymentText = pasteboard.hasStrings
    }

    func dismissPrompt() {
        hasPendingPaymentText = false
    }

    func readClipboardText() -> String? {
        UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
