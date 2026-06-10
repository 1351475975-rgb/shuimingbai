import SwiftUI
import SwiftData

struct ManualEntryView: View {
    @State private var inputText = ""
    @State private var pendingParsed: ParsedPayment?
    @State private var showConfirmSheet = false
    @State private var showManualSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("粘贴支付成功页文本、银行短信或任意含金额的文本，点击解析。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("支付文本") {
                    TextEditor(text: $inputText)
                        .frame(minHeight: 160)
                }

                Section {
                    Button("解析并记账") {
                        parseInput()
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("手动填写") {
                        showManualSheet = true
                    }
                }
            }
            .navigationTitle("手动记账")
            .alert("提示", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showConfirmSheet) {
                if let pendingParsed {
                    ConfirmExpenseSheet(parsed: pendingParsed) {
                        inputText = ""
                        self.pendingParsed = nil
                    }
                }
            }
            .sheet(isPresented: $showManualSheet) {
                ConfirmExpenseSheet(manual: "其他") {
                    inputText = ""
                }
            }
        }
    }

    private func parseInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = PaymentParser.parse(text) else {
            errorMessage = "未能识别支付信息，将打开手动确认页"
            pendingParsed = ParsedPayment(
                amount: 0,
                merchant: nil,
                category: "其他",
                time: .now,
                source: .manual,
                confidence: .low,
                rawText: text
            )
            showConfirmSheet = true
            return
        }
        pendingParsed = parsed
        showConfirmSheet = true
    }
}
