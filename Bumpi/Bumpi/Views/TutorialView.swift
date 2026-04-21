import SwiftUI

struct TutorialView: View {
    var onFinish: () -> Void

    @State private var pageIndex: Int = 0

    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "heart.text.square.fill",
            title: "Hear Your Baby",
            body: "Bumpi uses your phone's microphone to capture the gentle rhythm of your baby's heartbeat."
        ),
        TutorialPage(
            icon: "record.circle.fill",
            title: "One Touch Recording",
            body: "Place your phone on your belly and tap record. We'll listen and extract the heartbeat."
        ),
        TutorialPage(
            icon: "tray.full.fill",
            title: "Keep the Memory",
            body: "Save recordings with a date stamp and share precious moments with loved ones."
        ),
        TutorialPage(
            icon: "exclamationmark.shield.fill",
            title: "Not a Medical Device",
            body: "Bumpi is for comfort and bonding. It is not a medical device and does not replace professional care."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                    TutorialPageView(page: page)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: advance) {
                Text(pageIndex == pages.count - 1 ? "Get Started" : "Next")
            }
            .buttonStyle(BumpiPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func advance() {
        if pageIndex < pages.count - 1 {
            withAnimation { pageIndex += 1 }
        } else {
            onFinish()
        }
    }
}

private struct TutorialPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
}

private struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            BabyIllustrationView(pulse: true, size: 200)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BumpiTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.system(size: 16))
                    .foregroundColor(BumpiTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding(.top, 40)
    }
}
