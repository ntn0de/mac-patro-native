import SwiftUI
import WidgetKit

struct NepaliDateDisplay {
    let gregorianDate: Date
    let nepaliDate: NepaliDate
    let dayString: String
    let monthName: String
    let yearString: String
    let dayOfWeekName: String
    let fullDateString: String
}

struct MacPatroWidgetEntry: TimelineEntry {
    let date: Date
    let display: NepaliDateDisplay?
    let today: WidgetToday
    let festivals: [WidgetFestival]
}

struct WidgetToday {
    let tithi: String
    let events: String

    static let empty = WidgetToday(tithi: "", events: "")
}

struct WidgetFestival: Identifiable {
    let title: String
    let dateLabel: String
    let daysRemaining: Int

    var id: String { "\(title)-\(daysRemaining)" }
}

struct MacPatroWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacPatroWidgetEntry {
        entry()
    }

    func getSnapshot(in context: Context, completion: @escaping (MacPatroWidgetEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacPatroWidgetEntry>) -> Void) {
        let currentEntry = entry()
        guard let nepaliDate = currentEntry.display?.nepaliDate else {
            completion(Timeline(entries: [currentEntry], policy: .after(nextUpdateDate())))
            return
        }

        Self.loadYearData(nepaliDate.bsYear) { yearData in
            let today = yearData.map { Self.today(from: $0, date: nepaliDate) } ?? .empty
            let festivals = yearData.map { Self.festivals(from: $0, year: nepaliDate.bsYear) } ?? []
            let entry = MacPatroWidgetEntry(date: Date(), display: currentEntry.display, today: today, festivals: festivals)
            completion(Timeline(entries: [entry], policy: .after(nextUpdateDate())))
        }
    }

    private func entry() -> MacPatroWidgetEntry {
        let date = Calendar.currentDateForNepalConversion
        guard let nepaliDate = DateConverter.toNepaliDate(from: date) else {
            return MacPatroWidgetEntry(date: Date(), display: nil, today: .empty, festivals: [])
        }

        let dayString = NumberFormatter.nepaliString(from: nepaliDate.bsDay)
        let monthName = NepaliMonth(rawValue: nepaliDate.bsMonth)?.name ?? ""
        let yearString = NumberFormatter.nepaliString(from: nepaliDate.bsYear)
        let dayOfWeekName = Self.nepaliWeekdays[nepaliDate.dayOfWeek] ?? nepaliDate.dayOfWeek
        let display = NepaliDateDisplay(
            gregorianDate: date,
            nepaliDate: nepaliDate,
            dayString: dayString,
            monthName: monthName,
            yearString: yearString,
            dayOfWeekName: dayOfWeekName,
            fullDateString: "\(dayOfWeekName) \(dayString), \(monthName) \(yearString)"
        )
        return MacPatroWidgetEntry(date: Date(), display: display, today: .empty, festivals: [])
    }

    private func nextUpdateDate() -> Date {
        Calendar.nepal.date(byAdding: .day, value: 1, to: Calendar.nepal.startOfDay(for: Date())) ?? Date().addingTimeInterval(24 * 60 * 60)
    }

    private static let nepaliWeekdays = [
        "Sunday": "आइतबार", "Monday": "सोमबार", "Tuesday": "मङ्गलबार",
        "Wednesday": "बुधबार", "Thursday": "बिहिबार", "Friday": "शुक्रबार",
        "Saturday": "शनिबार"
    ]

    private static func loadYearData(_ year: Int, completion: @escaping (YearData?) -> Void) {
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MacPatroWidget/\(year).json")
        let cachedData = cache.flatMap { try? Data(contentsOf: $0) }.flatMap { try? JSONDecoder().decode(YearData.self, from: $0) }

        guard let url = URL(string: "\(RemoteURL.urlString)\(year).json") else {
            completion(cachedData)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            let remoteData = data.flatMap { try? JSONDecoder().decode(YearData.self, from: $0) }
            if let remoteData, remoteData.data.count == 12 {
                if let cache {
                    try? FileManager.default.createDirectory(at: cache.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try? data?.write(to: cache)
                }
                completion(remoteData)
            } else {
                completion(cachedData)
            }
        }.resume()
    }

    private static func today(from yearData: YearData, date: NepaliDate) -> WidgetToday {
        guard let day = yearData.data.first(where: { $0.month == date.bsMonth })?.days.first(where: { Int($0.dayInEn) == date.bsDay }) else {
            return .empty
        }
        return WidgetToday(tithi: day.tithi ?? "", events: day.event == "--" ? "" : day.event)
    }

    private static func festivals(from yearData: YearData, year: Int) -> [WidgetFestival] {
        let today = Calendar.nepal.startOfDay(for: Date())
        return yearData.data.flatMap { month in
            month.days.compactMap { day in
                guard !day.event.isEmpty, day.event != "--",
                      let dayNumber = Int(day.dayInEn)
                else { return nil }

                let nepaliDate = NepaliDate(bsYear: year, bsMonth: month.month, bsDay: dayNumber)
                guard let date = DateConverter.toGregorianDate(from: nepaliDate), date > today else { return nil }

                let remaining = Calendar.nepal.dateComponents([.day], from: today, to: Calendar.nepal.startOfDay(for: date)).day ?? 0
                let weekday = nepaliWeekdays[nepaliDate.dayOfWeek] ?? nepaliDate.dayOfWeek
                let monthName = NepaliMonth(rawValue: month.month)?.name ?? ""
                let dateLabel = "\(weekday), \(NumberFormatter.nepaliString(from: dayNumber)) \(monthName)"
                return WidgetFestival(title: day.event, dateLabel: dateLabel, daysRemaining: remaining)
            }
        }
        .sorted { $0.daysRemaining < $1.daysRemaining }
        .prefix(3)
        .map { $0 }
    }
}

struct MacPatroWidget: Widget {
    let kind = "MacPatroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacPatroWidgetProvider()) { entry in
            MacPatroWidgetView(entry: entry)
        }
        .configurationDisplayName("Mac Patro")
        .description("Nepali date, calendar, and upcoming festivals.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MacPatroWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MacPatroWidgetEntry

    var body: some View {
        if #available(macOS 14.0, *) {
            content.containerBackground(for: .widget) {
                WidgetColors.background
            }
        } else {
            content.background(WidgetColors.background)
        }
    }

    private var content: some View {
        Group {
            if family == .systemSmall {
                SmallWidgetView(display: entry.display)
            } else {
                MediumWidgetView(display: entry.display, today: entry.today, festivals: entry.festivals)
            }
        }
        .widgetURL(URL(string: "macpatro://calendar"))
    }
}

private struct SmallWidgetView: View {
    let display: NepaliDateDisplay?

    var body: some View {
        VStack(spacing: 5) {
            Text(display?.dayOfWeekName ?? "नेपाली पात्रो")
                .font(.headline)
                .foregroundStyle(WidgetColors.accent)
            Text(display?.dayString ?? "–")
                .font(.system(size: 52, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            Text("\(display?.monthName ?? "") \(display?.yearString ?? "")")
                .font(.headline)
                .foregroundStyle(.primary)
            Text(DateConverter.formatEnglishDate(date: display?.gregorianDate ?? Date()))
                .font(.caption)
                .foregroundStyle(WidgetColors.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(display?.fullDateString ?? "Nepali date")
    }
}

private struct MediumWidgetView: View {
    let display: NepaliDateDisplay?
    let today: WidgetToday
    let festivals: [WidgetFestival]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(display?.dayOfWeekName ?? "नेपाली पात्रो")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetColors.accent)
                Text(display?.dayString ?? "–")
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Text([today.tithi, "\(display?.monthName ?? "") \(display?.yearString ?? "")"].filter { !$0.isEmpty }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(WidgetColors.secondary)
                    .lineLimit(1)
                Text(DateConverter.formatEnglishDate(date: display?.gregorianDate ?? Date()))
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.secondary)
                if !today.events.isEmpty {
                    HStack(spacing: 6) {
                        Capsule()
                            .fill(WidgetColors.secondary)
                            .frame(width: 3)
                        Text(today.events)
                            .font(.caption)
                            .foregroundStyle(WidgetColors.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(WidgetColors.todayCard, in: RoundedRectangle(cornerRadius: 7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                if festivals.isEmpty {
                    Text("No upcoming festivals")
                        .font(.caption)
                        .foregroundStyle(WidgetColors.secondary)
                } else {
                    ForEach(festivals) { festival in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(festival.dateLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(WidgetColors.secondary)
                            HStack(spacing: 6) {
                                Capsule()
                                    .fill(WidgetColors.accent)
                                    .frame(width: 3)
                                Text(festival.title)
                                    .font(.caption)
                                    .foregroundStyle(WidgetColors.accent)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(WidgetColors.festivalCard, in: RoundedRectangle(cornerRadius: 7))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
    }
}

private enum WidgetColors {
    static let background = Color(nsColor: .windowBackgroundColor)
    static let accent = Color.accentColor
    static let secondary = Color.secondary
    static let todayCard = Color.gray.opacity(0.16)
    static let festivalCard = Color.accentColor.opacity(0.14)
}

@main
struct MacPatroWidgets: WidgetBundle {
    var body: some Widget {
        MacPatroWidget()
    }
}
