import SwiftUI
import SwiftData

struct CategoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @State private var newCategoryName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("预设分类") {
                    ForEach(categories.filter(\.isPreset)) { category in
                        Text(category.name)
                    }
                }

                Section("自定义分类") {
                    if categories.filter({ !$0.isPreset }).isEmpty {
                        Text("暂无自定义分类")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories.filter { !$0.isPreset }) { category in
                            Text(category.name)
                        }
                        .onDelete(perform: deleteCustomCategories)
                    }
                }

                Section("添加分类") {
                    HStack {
                        TextField("分类名称", text: $newCategoryName)
                        Button("添加") {
                            addCategory()
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("分类管理")
            .onAppear {
                ExpenseCategory.seedIfNeeded(in: modelContext)
            }
        }
    }

    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        guard !categories.contains(where: { $0.name == name }) else { return }

        let nextOrder = (categories.map(\.sortOrder).max() ?? 0) + 1
        modelContext.insert(ExpenseCategory(name: name, isPreset: false, sortOrder: nextOrder))
        try? modelContext.save()
        newCategoryName = ""
    }

    private func deleteCustomCategories(at offsets: IndexSet) {
        let custom = categories.filter { !$0.isPreset }
        for index in offsets {
            modelContext.delete(custom[index])
        }
        try? modelContext.save()
    }
}
