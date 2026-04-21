import SwiftUI

struct DocumentOptionsSheet: View {
    let document: PDFDocumentItem
    var onRename: () -> Void
    var onManagePages: () -> Void
    var onShare: () -> Void
    var onSetPassword: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Document Options")
                .font(.title3.bold())
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 12)

            row(icon: "pencil", title: "Rename Document", subtitle: "Change the document name", action: onRename)
            row(icon: "rectangle.stack", title: "Manage Pages", subtitle: "Rearrange, add, or remove pages", action: onManagePages)
            row(icon: "square.and.arrow.up", title: "Share", subtitle: "Share this document", action: onShare)
            row(icon: document.isPasswordProtected ? "lock.open.fill" : "lock.fill",
                title: document.isPasswordProtected ? "Change Password" : "Set Password",
                subtitle: document.isPasswordProtected ? "Update or remove password" : "Protect document with password",
                action: onSetPassword)
            row(icon: "trash", title: "Delete Document", subtitle: "Remove from library", tint: .red, action: onDelete)

            Spacer(minLength: 12)
        }
    }

    @ViewBuilder
    private func row(icon: String, title: String, subtitle: String, tint: Color = Theme.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Theme.primaryText)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
