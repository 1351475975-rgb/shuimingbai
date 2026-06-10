import SwiftUI

struct MainTabView: View {
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

            CategoryManageView()
                .tabItem {
                    Label("分类", systemImage: "tag")
                }
        }
    }
}
