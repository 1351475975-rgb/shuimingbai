import SwiftUI

struct MainTabView: View {
    @State private var appState = AppState.shared

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("账单", systemImage: "list.bullet.rectangle")
                }

            ManualEntryView()
                .tabItem {
                    Label("记账", systemImage: "plus.circle")
                }

            OnboardingShortcutsView()
                .tabItem {
                    Label("自动记账", systemImage: "bell.badge")
                }

            CategoryManageView()
                .tabItem {
                    Label("分类", systemImage: "tag")
                }
        }
        .sheet(isPresented: $appState.showConfirmSheet) {
            if let parsed = appState.pendingParsed {
                ConfirmExpenseSheet(parsed: parsed) {
                    appState.clearPending()
                }
            }
        }
    }
}
