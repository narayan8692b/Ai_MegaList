import SwiftUI

struct TrackersListView: View {
    @EnvironmentObject private var store: HabitStore
    @State private var showingAdd = false

    private var quote: Quote { Quote.daily() }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(store.habits) { habit in
                        NavigationLink(value: habit) {
                            HabitCardView(habit: habit, now: store.tick)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Reset Streak", role: .destructive) {
                                store.resetStreak(for: habit)
                            }
                            Button("Delete", role: .destructive) {
                                store.delete(habit)
                            }
                        }
                    }

                    motivationCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("My Trackers")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColor.accent)
                    }
                }
            }
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(habitID: habit.id)
            }
            .sheet(isPresented: $showingAdd) {
                AddHabitView()
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.red))
                        .shadow(color: Color.red.opacity(0.45), radius: 12, x: 0, y: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var motivationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "quote.opening")
                .foregroundStyle(AppColor.accent)
            Text("\"\(quote.text)\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Text("— \(quote.author)")
                .font(.system(size: 12))
                .foregroundStyle(AppColor.mutedText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
