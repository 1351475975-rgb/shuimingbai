import SwiftUI
import SwiftData

struct ConfirmExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var viewModel: ConfirmExpenseViewModel
    let onSaved: () -> Void

    init(parsed: ParsedPayment, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: ConfirmExpenseViewModel(parsed: parsed))
        self.onSaved = onSaved
    }

    init(manual category: String = "其他", onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: ConfirmExpenseViewModel(manual: category))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.confidence == .low {
                    Section {
                        Label("解析置信度较低，请核对金额和商家", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Section("金额") {
                    TextField("0.00", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                }

                Section("商家") {
                    TextField("商家名称", text: $viewModel.merchant)
                }

                Section("分类") {
                    Picker("分类", selection: $viewModel.category) {
                        ForEach(categoryNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }

                Section("时间") {
                    DatePicker("消费时间", selection: $viewModel.time)
                }

                Section("备注") {
                    TextField("可选备注", text: $viewModel.note)
                }

                if !viewModel.rawText.isEmpty {
                    Section("原始文本") {
                        Text(viewModel.rawText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("确认记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!viewModel.isValid)
                }
            }
        }
        .onAppear {
            ExpenseCategory.seedIfNeeded(in: modelContext)
        }
    }

    private var categoryNames: [String] {
        let names = categories.map(\.name)
        return names.isEmpty ? ExpenseCategory.presetNames : names
    }

    private func save() {
        guard let record = viewModel.makeRecord() else { return }
        modelContext.insert(record)
        try? modelContext.save()
        onSaved()
        dismiss()
    }
}
