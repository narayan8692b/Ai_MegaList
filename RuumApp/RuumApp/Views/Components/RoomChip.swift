import SwiftUI

struct RoomChip: View {
    let room: Room
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: room.sfSymbol)
                    .font(.system(size: 18, weight: .medium))
                Text(room.name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 84, height: 64)
            .padding(.horizontal, 4)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.ruumTeal : Color.ruumCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.ruumTealDark : Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
