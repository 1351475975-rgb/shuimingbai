import SwiftUI
import SwiftData

@main
struct ClipboardExpenseApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self])
    }
}
