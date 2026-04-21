import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var profileStore: BabyProfileStore

    @State private var name: String = ""
    @State private var dueDate: Date = Calendar.current.date(byAdding: .month, value: 5, to: Date()) ?? Date()

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                BabyIllustrationView(pulse: true, size: 180)
                    .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Let's set up")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(BumpiTheme.textPrimary)
                    Text("Tell us a little about your baby")
                        .font(.system(size: 15))
                        .foregroundColor(BumpiTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Baby's name or nickname")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(BumpiTheme.textSecondary)
                        TextField("Lily", text: $name)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(BumpiTheme.softPink)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due date")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(BumpiTheme.textSecondary)
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                        .tint(BumpiTheme.primary)
                        .padding(12)
                        .background(BumpiTheme.softPink)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)

                Button(action: save) {
                    Text("Continue")
                }
                .buttonStyle(BumpiPrimaryButtonStyle(enabled: !trimmedName.isEmpty))
                .disabled(trimmedName.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func save() {
        let profile = BabyProfile(name: trimmedName, dueDate: dueDate)
        profileStore.save(profile)
    }
}
