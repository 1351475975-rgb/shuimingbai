import Foundation
import SwiftData

@Model
final class ExpenseRecord {
    var id: UUID
    var amount: Decimal
    var category: String
    var note: String?
    var merchant: String?
    var time: Date
    var source: String
    var rawText: String?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        category: String,
        note: String? = nil,
        merchant: String? = nil,
        time: Date = .now,
        source: String = "manual",
        rawText: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.merchant = merchant
        self.time = time
        self.source = source
        self.rawText = rawText
    }
}
