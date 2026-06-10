import Foundation
import Observation

@Observable
final class ConfirmExpenseViewModel {
    var amountText: String
    var merchant: String
    var category: String
    var note: String
    var time: Date
    var source: PaymentSource
    var confidence: ParseConfidence
    var rawText: String

    init(parsed: ParsedPayment) {
        amountText = NSDecimalNumber(decimal: parsed.amount).stringValue
        merchant = parsed.merchant ?? ""
        category = parsed.category
        note = ""
        time = parsed.time
        source = parsed.source
        confidence = parsed.confidence
        rawText = parsed.rawText
    }

    init(manual category: String = "其他") {
        amountText = ""
        merchant = ""
        self.category = category
        note = ""
        time = .now
        source = .manual
        confidence = .high
        rawText = ""
    }

    var amount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: ""))
    }

    var isValid: Bool {
        guard let amount, amount > 0 else { return false }
        return !category.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func makeRecord() -> ExpenseRecord? {
        guard let amount, isValid else { return nil }
        return ExpenseRecord(
            amount: amount,
            category: category,
            note: note.isEmpty ? nil : note,
            merchant: merchant.isEmpty ? nil : merchant,
            time: time,
            source: source.rawValue,
            rawText: rawText.isEmpty ? nil : rawText
        )
    }
}
