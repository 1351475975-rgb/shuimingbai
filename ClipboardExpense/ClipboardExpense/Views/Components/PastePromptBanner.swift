import SwiftUI

struct PastePromptBanner: View {
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard.fill")
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("检测到剪贴板有新内容")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("点击一键解析记账")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding()
        .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onTap)
        .accessibilityLabel("检测到支付信息，点击记账")
    }
}
