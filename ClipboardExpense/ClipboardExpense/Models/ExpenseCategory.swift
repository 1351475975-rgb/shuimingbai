import Foundation
import SwiftData

@Model
final class ExpenseCategory {
    var id: UUID
    var name: String
    var isPreset: Bool
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, isPreset: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.isPreset = isPreset
        self.sortOrder = sortOrder
    }

    static let presetNames = ["餐饮", "交通", "购物", "生活", "娱乐", "其他"]

    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseCategory>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (index, name) in presetNames.enumerated() {
            context.insert(ExpenseCategory(name: name, isPreset: true, sortOrder: index))
        }
        try? context.save()
    }
}
