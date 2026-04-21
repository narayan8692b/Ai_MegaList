import SwiftUI

struct RootView: View {
    @EnvironmentObject var profileStore: BabyProfileStore
    @AppStorage("didCompleteTutorial") private var didCompleteTutorial = false

    var body: some View {
        ZStack {
            BumpiTheme.background.ignoresSafeArea()

            if !didCompleteTutorial {
                TutorialView(onFinish: { didCompleteTutorial = true })
                    .transition(.opacity)
            } else if profileStore.profile == nil {
                OnboardingView()
                    .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: didCompleteTutorial)
        .animation(.easeInOut(duration: 0.35), value: profileStore.profile?.id)
    }
}
