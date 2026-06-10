import Foundation
import Observation

/// Intent / 深链与 UI 之间的桥梁（半自动：一律弹确认页）
@Observable
@MainActor
final class AppState {
    static let shared = AppState()

    var pendingParsed: ParsedPayment?
    var showConfirmSheet = false

    private init() {}

    func presentPaymentText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let parsed = PaymentParser.parse(trimmed) {
            presentParsed(parsed)
        } else {
            presentParsed(.manualFallback(rawText: trimmed))
        }
    }

    func presentParsed(_ parsed: ParsedPayment) {
        pendingParsed = parsed
        showConfirmSheet = true
    }

    func clearPending() {
        pendingParsed = nil
        showConfirmSheet = false
    }
}

extension ParsedPayment {
    static func manualFallback(rawText: String) -> ParsedPayment {
        ParsedPayment(
            amount: 0,
            merchant: nil,
            category: "其他",
            time: .now,
            source: .manual,
            confidence: .low,
            rawText: rawText
        )
    }
}
