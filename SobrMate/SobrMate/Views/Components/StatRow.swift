import SwiftUI

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var tint: Color = AppColor.accent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
    }
}

struct SectionCard<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.mutedText)
                    .padding(.horizontal, 4)
            }
            VStack(spacing: 0) { content }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
