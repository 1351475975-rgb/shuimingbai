import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \ExpenseRecord.time, order: .reverse) private var records: [ExpenseRecord]

    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                List {
                    Section("支出概览") {
                        statsRow
                    }

                    Section("账单记录") {
                        if records.isEmpty {
                            ContentUnavailableView(
                                "暂无账单",
                                systemImage: "tray",
                                description: Text("复制支付文本后点击「粘贴记账」")
                            )
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(StatsCalculator.groupedByDay(records: records), id: \.0) { day, dayRecords in
                                Section(day.formatted(date: .abbreviated, time: .omitted)) {
                                    ForEach(dayRecords, id: \.id) { record in
                                        ExpenseRow(record: record)
                                    }
                                    .onDelete { offsets in
                                        deleteRecords(dayRecords, at: offsets)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .padding(.top, viewModel.clipboardMonitor.hasPendingPaymentText ? 64 : 0)

                if viewModel.clipboardMonitor.hasPendingPaymentText {
                    PastePromptBanner(
                        onTap: { viewModel.pasteFromClipboard() },
                        onDismiss: { viewModel.clipboardMonitor.dismissPrompt() }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("剪贴板记账")
            .safeAreaInset(edge: .bottom) {
                pasteButton
            }
            .alert("提示", isPresented: .init(
                get: { viewModel.parseErrorMessage != nil },
                set: { if !$0 { viewModel.parseErrorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(viewModel.parseErrorMessage ?? "")
            }
            .sheet(isPresented: $viewModel.showConfirmSheet) {
                if let parsed = viewModel.pendingParsedPayment {
                    ConfirmExpenseSheet(parsed: parsed) {
                        viewModel.resetConfirmState()
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.handleBecomeActive()
                }
            }
            .onAppear {
                ExpenseCategory.seedIfNeeded(in: modelContext)
                viewModel.handleBecomeActive()
            }
        }
    }

    private var statsRow: some View {
        let today = StatsCalculator.today(records: records)
        let week = StatsCalculator.thisWeek(records: records)
        let month = StatsCalculator.thisMonth(records: records)

        return HStack(spacing: 12) {
            StatSummaryCard(title: "今日", amount: today.total, count: today.count)
            StatSummaryCard(title: "本周", amount: week.total, count: week.count)
            StatSummaryCard(title: "本月", amount: month.total, count: month.count)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private var pasteButton: some View {
        Button {
            viewModel.pasteFromClipboard()
        } label: {
            Label("粘贴记账", systemImage: "doc.on.clipboard")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func deleteRecords(_ dayRecords: [ExpenseRecord], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(dayRecords[index])
        }
        try? modelContext.save()
    }
}

struct ExpenseRow: View {
    let record: ExpenseRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.merchant ?? record.category)
                    .font(.body.bold())
                HStack(spacing: 8) {
                    Text(record.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                    Text(record.time.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(CurrencyFormatter.string(from: record.amount))
                .font(.body.bold())
        }
        .padding(.vertical, 2)
    }
}
