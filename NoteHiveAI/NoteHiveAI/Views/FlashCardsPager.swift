import SwiftUI

struct FlashCardsPager: View {
    let cards: [FlashCard]
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false

    var body: some View {
        if cards.isEmpty {
            EmptyTabState(
                icon: "rectangle.on.rectangle",
                title: "No flash cards yet",
                subtitle: "Tap the refresh icon to generate flash cards from your transcription."
            )
        } else {
            VStack(spacing: 16) {
                TabView(selection: $currentIndex) {
                    ForEach(cards.indices, id: \.self) { idx in
                        CardFace(card: cards[idx], isFlipped: isFlipped && idx == currentIndex)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isFlipped.toggle()
                                }
                            }
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(minHeight: 240)
                .onChange(of: currentIndex) { _, _ in isFlipped = false }

                HStack {
                    Button {
                        withAnimation { currentIndex = max(0, currentIndex - 1); isFlipped = false }
                    } label: {
                        Image(systemName: "chevron.left")
                            .padding(10)
                            .foregroundColor(Theme.textPrimary)
                            .background(Theme.pillInactive)
                            .clipShape(Circle())
                    }
                    .disabled(currentIndex == 0)

                    Spacer()

                    Text("\(currentIndex + 1) / \(cards.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    Button {
                        withAnimation { currentIndex = min(cards.count - 1, currentIndex + 1); isFlipped = false }
                    } label: {
                        Image(systemName: "chevron.right")
                            .padding(10)
                            .foregroundColor(Theme.textPrimary)
                            .background(Theme.pillInactive)
                            .clipShape(Circle())
                    }
                    .disabled(currentIndex >= cards.count - 1)
                }
                .padding(.horizontal, 8)

                Text("Tap card to reveal answer")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
    }
}

private struct CardFace: View {
    let card: FlashCard
    let isFlipped: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
                )

            VStack(spacing: 12) {
                Text(isFlipped ? "Answer" : "Question")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.accentSoft)
                    .clipShape(Capsule())

                Text(isFlipped ? card.answer : card.question)
                    .font(.body.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                    .id(isFlipped)
            }
            .padding(20)
        }
        .frame(minHeight: 220)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }
}
