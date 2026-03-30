import SwiftUI
import SwiftData

struct PuzzleCalendarView: View {
    let savedStates: [GameState]
    @State private var displayedMonth: Date = .now

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    private let berryBlue = Color("BerryBlue")

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    shiftMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                }

                Spacer()

                Text(monthYearString)
                    .font(.subheadline.bold())

                Spacer()

                Button {
                    shiftMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.bold())
                }
                .disabled(isCurrentMonth)
            }

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { day in
                    if let day {
                        let solvedCount = solvedCountForDay(day)
                        let isToday = calendar.isDateInToday(day)
                        let isFuture = day > .now

                        ZStack {
                            if isToday {
                                Circle()
                                    .strokeBorder(berryBlue, lineWidth: 1.5)
                                    .frame(width: 32, height: 32)
                            }

                            Circle()
                                .fill(colorForSolvedCount(solvedCount, isFuture: isFuture))
                                .frame(width: 28, height: 28)

                            Text("\(calendar.component(.day, from: day))")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(textColorForSolvedCount(solvedCount, isFuture: isFuture))
                        }
                        .frame(height: 36)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
    }

    // MARK: - Data

    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay)

        // Pad leading empty cells (Sunday = 1)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }

    private func solvedCountForDay(_ date: Date) -> Int {
        let dayString = "\(calendar.component(.day, from: date)) \(calendar.component(.month, from: date)) \(calendar.component(.year, from: date))"
        return savedStates.filter { $0.dateString == dayString && $0.solved && $0.source == "Daily" }.count
    }

    private func colorForSolvedCount(_ count: Int, isFuture: Bool) -> Color {
        if isFuture { return .clear }
        return switch count {
        case 0: .clear
        case 1: berryBlue.opacity(0.2)
        case 2: berryBlue.opacity(0.5)
        default: berryBlue
        }
    }

    private func textColorForSolvedCount(_ count: Int, isFuture: Bool) -> Color {
        if isFuture { return Color.gray.opacity(0.3) }
        if count >= 3 { return .white }
        return .primary
    }

    // MARK: - Navigation

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month)
    }

    private func shiftMonth(_ delta: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newMonth
            }
        }
    }
}
