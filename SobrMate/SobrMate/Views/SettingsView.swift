import SwiftUI

struct SettingsView: View {
    @AppStorage("sobrmate.notifications") private var notificationsEnabled: Bool = true
    @AppStorage("sobrmate.hapticFeedback") private var hapticsEnabled: Bool = true
    @AppStorage("sobrmate.startOfWeek") private var startOnMonday: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Daily Check-in Reminder", isOn: $notificationsEnabled)
                    Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                }

                Section("Calendar") {
                    Toggle("Start Week on Monday", isOn: $startOnMonday)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Support", destination: URL(string: "mailto:support@example.com")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
