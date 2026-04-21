import SwiftUI

struct AddHabitView: View {
    @EnvironmentObject private var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = "🚭"
    @State private var palette: HabitPalette = .blue
    @State private var startDate: Date = Date()
    @State private var motivation: String = ""

    private let suggestedEmojis = ["🚭", "🍺", "📱", "🍭", "🎰", "☕️", "🧃", "🛒", "🎮", "🚬"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Name (e.g. Alcohol)", text: $name)
                    HStack {
                        Text("Icon")
                        Spacer()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(suggestedEmojis, id: \.self) { option in
                                    Text(option)
                                        .font(.system(size: 22))
                                        .padding(8)
                                        .background(Circle().fill(option == emoji ? palette.solid.opacity(0.35) : Color.clear))
                                        .onTapGesture { emoji = option }
                                }
                            }
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(HabitPalette.allCases) { option in
                            Circle()
                                .fill(LinearGradient(colors: option.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 44)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: option == palette ? 2 : 0)
                                )
                                .onTapGesture { palette = option }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Timeline") {
                    DatePicker("Clean Since", selection: $startDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                }

                Section("Why I'm Doing This") {
                    TextField("Your motivation…", text: $motivation, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Tracker")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let habit = Habit(
                            name: name.trimmingCharacters(in: .whitespaces),
                            emoji: emoji,
                            palette: palette,
                            startDate: startDate,
                            motivation: motivation
                        )
                        store.add(habit)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
