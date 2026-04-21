import SwiftUI

struct EditHabitView: View {
    @EnvironmentObject private var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var working: Habit

    init(habit: Habit) {
        _working = State(initialValue: habit)
    }

    private let suggestedEmojis = ["🚭", "🍺", "📱", "🍭", "🎰", "☕️", "🧃", "🛒", "🎮", "🚬"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Name", text: $working.name)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(suggestedEmojis, id: \.self) { option in
                                Text(option)
                                    .font(.system(size: 22))
                                    .padding(8)
                                    .background(Circle().fill(option == working.emoji ? working.palette.solid.opacity(0.35) : Color.clear))
                                    .onTapGesture { working.emoji = option }
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
                                .overlay(Circle().stroke(Color.white, lineWidth: option == working.palette ? 2 : 0))
                                .onTapGesture { working.palette = option }
                        }
                    }
                }

                Section("Started") {
                    DatePicker("Clean Since", selection: $working.startDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                }

                Section("Motivation") {
                    TextField("Your reason…", text: $working.motivation, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Tracker")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.update(working)
                        dismiss()
                    }
                    .disabled(working.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
