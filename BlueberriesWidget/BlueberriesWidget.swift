//
//  BlueberriesWidget.swift
//  BlueberriesWidget
//
//  Created by James Brooks on 30/03/2026.
//

import WidgetKit
import SwiftUI

private let berryBlue = Color(red: 0.208, green: 0.518, blue: 0.894)
private let difficulties = ["Standard", "Advanced", "Expert"]

struct DailyProgressEntry: TimelineEntry {
    let date: Date
    let solvedCount: Int
    let totalCount: Int
    let currentStreak: Int
}

struct DailyProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyProgressEntry {
        DailyProgressEntry(date: .now, solvedCount: 1, totalCount: 3, currentStreak: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyProgressEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyProgressEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.alt-three.Berroku") ?? .standard
        let solved = defaults.integer(forKey: "widget.solvedCount")
        let streak = defaults.integer(forKey: "widget.currentStreak")

        let entry = DailyProgressEntry(
            date: .now,
            solvedCount: solved,
            totalCount: 3,
            currentStreak: streak
        )

        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// MARK: - Small Widget

private struct SmallWidgetView: View {
    let entry: DailyProgressEntry

    private var allSolved: Bool { entry.solvedCount >= entry.totalCount }

    var body: some View {
        VStack(spacing: 0) {
            // Berry icon
            ZStack {
                Circle()
                    .fill(berryBlue.gradient)
                    .frame(width: 40, height: 40)
                Image(systemName: "circle.grid.3x3.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 6)

            // Progress berries
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    let solved = i < entry.solvedCount
                    ZStack {
                        Circle()
                            .fill(solved ? berryBlue : Color.gray.opacity(0.2))
                            .frame(width: 24, height: 24)
                        if solved {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(i + 1)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.bottom, 6)

            if allSolved {
                Label("Complete!", systemImage: "sparkles")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            } else {
                Text("\(entry.solvedCount)/\(entry.totalCount)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if entry.currentStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("\(entry.currentStreak)")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                }
                .padding(.top, 2)
            }
        }
    }
}

// MARK: - Medium Widget

private struct MediumWidgetView: View {
    let entry: DailyProgressEntry

    private var allSolved: Bool { entry.solvedCount >= entry.totalCount }

    var body: some View {
        HStack(spacing: 16) {
            // Left: branding + streak
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(berryBlue.gradient)
                            .frame(width: 36, height: 36)
                        Image(systemName: "circle.grid.3x3.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Berroku")
                            .font(.subheadline.bold())
                        Text("Today's Puzzles")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if entry.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(entry.currentStreak) day streak")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }

                if allSolved {
                    Label("All complete!", systemImage: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            // Right: puzzle progress rows
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    let solved = i < entry.solvedCount
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(solved ? berryBlue : Color.gray.opacity(0.15))
                                .frame(width: 22, height: 22)
                            if solved {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(i + 1)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(difficulties[i])
                            .font(.caption)
                            .foregroundStyle(solved ? .primary : .secondary)

                        Spacer()

                        if solved {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .frame(width: 140)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Entry View

struct BlueberriesWidgetEntryView: View {
    var entry: DailyProgressEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct BlueberriesWidget: Widget {
    let kind = "BlueberriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyProgressProvider()) { entry in
            BlueberriesWidgetEntryView(entry: entry)
                .containerBackground(berryBlue.gradient.opacity(0.08), for: .widget)
        }
        .configurationDisplayName("Daily Progress")
        .description("Track your daily puzzle progress and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    BlueberriesWidget()
} timeline: {
    DailyProgressEntry(date: .now, solvedCount: 0, totalCount: 3, currentStreak: 0)
    DailyProgressEntry(date: .now, solvedCount: 2, totalCount: 3, currentStreak: 7)
    DailyProgressEntry(date: .now, solvedCount: 3, totalCount: 3, currentStreak: 12)
}

#Preview(as: .systemMedium) {
    BlueberriesWidget()
} timeline: {
    DailyProgressEntry(date: .now, solvedCount: 1, totalCount: 3, currentStreak: 3)
    DailyProgressEntry(date: .now, solvedCount: 3, totalCount: 3, currentStreak: 14)
}
