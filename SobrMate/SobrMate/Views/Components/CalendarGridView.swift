import SwiftUI

struct CalendarGridView: View {
    let habit: Habit
    @State private var visibleMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.veryShortStandaloneWeekdaySymbols

    var body: some View {
        VStack(spacing: 14) {
            header

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColor.mutedText)
                }

                ForEach(daysGrid(), id: \.self) { date in
                    if let date {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var header: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left").foregroundStyle(.white)
            }
            Spacer()
            Text(monthTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right").foregroundStyle(.white)
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: visibleMonth).capitalized
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isClean = isCleanDay(date)
        let isFuture = date > Date()

        ZStack {
            Circle()
                .fill(isToday ? habit.palette.solid.opacity(0.25) : Color.clear)
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundStyle(isFuture ? AppColor.mutedText.opacity(0.5) : .white)
            if isClean {
                Circle()
                    .fill(habit.palette.solid)
                    .frame(width: 4, height: 4)
                    .offset(y: 12)
            }
        }
        .frame(height: 32)
    }

    private func isCleanDay(_ date: Date) -> Bool {
        let start = calendar.startOfDay(for: habit.effectiveStart)
        let target = calendar.startOfDay(for: date)
        return target >= start && target <= calendar.startOfDay(for: Date())
    }

    private func shiftMonth(by offset: Int) {
        if let next = calendar.date(byAdding: .month, value: offset, to: visibleMonth) {
            visibleMonth = next
        }
    }

    private func daysGrid() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: visibleMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth))
        else { return [] }

        let leadingBlanks = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: first) {
                cells.append(d)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}
