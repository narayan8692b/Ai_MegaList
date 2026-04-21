import SwiftUI

struct ModeChipPicker: View {
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CollectibleMode.allCases) { mode in
                    chip(for: mode)
                }
            }
            .padding(.horizontal)
        }
    }

    private func chip(for mode: CollectibleMode) -> some View {
        let isSelected = selection == mode.rawValue
        return Button {
            selection = mode.rawValue
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.systemImage)
                Text(mode.rawValue)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected
                               ? mode.accentColor
                               : Color.white)
                    .shadow(color: .black.opacity(isSelected ? 0 : 0.05),
                            radius: 4, x: 0, y: 1)
            )
            .overlay(
                Capsule().strokeBorder(mode.accentColor.opacity(isSelected ? 0 : 0.25))
            )
            .foregroundStyle(isSelected ? .white : Color.brandInk)
        }
    }
}

#Preview {
    struct Demo: View {
        @State var selection = CollectibleMode.stamp.rawValue
        var body: some View {
            ModeChipPicker(selection: $selection)
                .padding(.vertical)
                .background(Color.brandCream)
        }
    }
    return Demo()
}
