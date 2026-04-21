import SwiftUI

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            if let trailing {
                Button(trailing) { trailingAction?() }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.ruumTeal)
            }
        }
    }
}
