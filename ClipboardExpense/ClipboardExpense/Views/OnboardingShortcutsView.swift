import SwiftUI

struct OnboardingShortcutsView: View {
    private let steps: [(String, String)] = [
        ("1. 开启通知预览", "设置 → 通知 → 微信/支付宝 → 允许通知 → 显示预览选「始终」"),
        ("2. 创建自动化", "快捷指令 App → 自动化 → + → 创建个人自动化"),
        ("3. 选择触发 App", "选「App」→ 勾选「微信」（支付宝另建一条）"),
        ("4. 筛选支付通知", "点「通知」→ 包含「支付」或「付款」或「元」（可选）"),
        ("5. 添加记账动作", "添加操作 → 搜索「剪贴板记账」→ 选「从通知记账」"),
        ("6. 传入通知文字", "在「支付文本」参数里选「快捷指令输入」或「通知的正文」"),
        ("7. 立即运行", "关闭「运行前询问」/ 打开「立即运行」（iOS 15.4+）"),
        ("8. 测试", "付一笔小额 → 应自动打开本 App 并弹出确认页")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("付完款后，微信/支付宝通知可自动触发记账（半自动：需点一次保存）。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("配置步骤") {
                    ForEach(steps, id: \.0) { title, detail in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.headline)
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("手动测试 Intent") {
                    Text("快捷指令 App → + → 添加操作 → 搜索「从通知记账」→ 粘贴一段支付文字 → 运行，应打开确认页。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("备用方式") {
                    Label("复制通知 → 打开 App → 粘贴记账", systemImage: "doc.on.clipboard")
                    Label("背面轻点 → 绑定「从剪贴板记账」", systemImage: "hand.tap")
                }
            }
            .navigationTitle("通知自动记账")
        }
    }
}
