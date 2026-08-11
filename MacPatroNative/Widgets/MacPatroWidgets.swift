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
    let monthDays: [WidgetCalendarDay]
    let isHoliday: Bool
}

struct WidgetCalendarDay: Identifiable {
    let id: Int
    let nepaliDay: String
    let isToday: Bool
    let isHoliday: Bool
    let isPlaceholder: Bool

    static func placeholder(id: Int) -> WidgetCalendarDay {
        WidgetCalendarDay(id: id, nepaliDay: "", isToday: false, isHoliday: false, isPlaceholder: true)
    }
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
        let now = Date()
        let current = entry(at: now)
        if let year = current.display?.nepaliDate.bsYear {
            completion(Self.makeEntry(at: now, yearData: Self.cachedYearData(year)))
        } else {
            completion(current)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacPatroWidgetEntry>) -> Void) {
        let now = Date()
        let currentEntry = entry(at: now)
        guard let nepaliDate = currentEntry.display?.nepaliDate else {
            completion(Timeline(entries: [currentEntry], policy: .after(Self.nextNepalMidnight(after: now))))
            return
        }

        // Prefer cache so the date updates even when the network is slow/offline.
        let cached = Self.cachedYearData(nepaliDate.bsYear)
        completion(Self.timeline(from: now, yearData: cached))

        Self.refreshYearData(nepaliDate.bsYear) { yearData in
            guard let yearData, yearData.data.count == 12 else { return }
            let cacheIsStale = cached.map { $0.lastUpdatedAt != yearData.lastUpdatedAt } ?? true
            guard cacheIsStale else { return }
            WidgetCenter.shared.reloadTimelines(ofKind: "MacPatroWidget.v2")
        }
    }

    private static func timeline(from now: Date, yearData: YearData?) -> Timeline<MacPatroWidgetEntry> {
        var entries = [makeEntry(at: now, yearData: yearData)]
        var cursor = Calendar.nepal.startOfDay(for: now)
        for _ in 0..<3 {
            guard let midnight = Calendar.nepal.date(byAdding: .day, value: 1, to: cursor) else { break }
            entries.append(makeEntry(at: midnight, yearData: yearData))
            cursor = midnight
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(at date: Date = Date()) -> MacPatroWidgetEntry {
        Self.makeEntry(at: date, yearData: nil)
    }

    private static func makeEntry(at date: Date, yearData: YearData?) -> MacPatroWidgetEntry {
        let conversionDate = Calendar.dateForNepalConversion(from: date)
        guard let nepaliDate = DateConverter.toNepaliDate(from: conversionDate) else {
            return MacPatroWidgetEntry(date: date, display: nil, today: .empty, festivals: [], monthDays: [], isHoliday: false)
        }

        let dayString = NumberFormatter.nepaliString(from: nepaliDate.bsDay)
        let monthName = NepaliMonth(rawValue: nepaliDate.bsMonth)?.name ?? ""
        let yearString = NumberFormatter.nepaliString(from: nepaliDate.bsYear)
        let dayOfWeekName = nepaliWeekdays[nepaliDate.dayOfWeek] ?? nepaliDate.dayOfWeek
        let display = NepaliDateDisplay(
            gregorianDate: date,
            nepaliDate: nepaliDate,
            dayString: dayString,
            monthName: monthName,
            yearString: yearString,
            dayOfWeekName: dayOfWeekName,
            fullDateString: "\(dayOfWeekName) \(dayString), \(monthName) \(yearString)"
        )

        let todayInfo = yearData.map { makeToday(from: $0, date: nepaliDate) } ?? .empty
        let festivals = yearData.map { makeFestivals(from: $0, year: nepaliDate.bsYear, on: date) } ?? []
        let monthDays = monthCalendarDays(for: nepaliDate, yearData: yearData)
        let isHoliday = monthDays.first(where: { $0.isToday })?.isHoliday ?? false
        return MacPatroWidgetEntry(
            date: date,
            display: display,
            today: todayInfo,
            festivals: festivals,
            monthDays: monthDays,
            isHoliday: isHoliday
        )
    }

    private static func nextNepalMidnight(after date: Date) -> Date {
        Calendar.nepal.date(byAdding: .day, value: 1, to: Calendar.nepal.startOfDay(for: date))
            ?? date.addingTimeInterval(24 * 60 * 60)
    }

    private static let nepaliWeekdays = [
        "Sunday": "आइतबार", "Monday": "सोमबार", "Tuesday": "मङ्गलबार",
        "Wednesday": "बुधबार", "Thursday": "बिहिबार", "Friday": "शुक्रबार",
        "Saturday": "शनिबार"
    ]

    private static func cacheURL(for year: Int) -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MacPatroWidget/\(year).json")
    }

    private static func cachedYearData(_ year: Int) -> YearData? {
        cacheURL(for: year)
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode(YearData.self, from: $0) }
    }

    private static func refreshYearData(_ year: Int, completion: @escaping (YearData?) -> Void) {
        guard let url = URL(string: "\(RemoteURL.urlString)\(year).json") else {
            completion(cachedYearData(year))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { data, _, _ in
            let remoteData = data.flatMap { try? JSONDecoder().decode(YearData.self, from: $0) }
            if let remoteData, remoteData.data.count == 12 {
                if let cache = cacheURL(for: year) {
                    try? FileManager.default.createDirectory(at: cache.deletingLastPathComponent(), withIntermediateDirectories: true)
                    if let data {
                        try? data.write(to: cache)
                    }
                }
                completion(remoteData)
            } else {
                completion(cachedYearData(year))
            }
        }.resume()
    }

    private static func makeToday(from yearData: YearData, date: NepaliDate) -> WidgetToday {
        guard let day = yearData.data.first(where: { $0.month == date.bsMonth })?.days.first(where: { Int($0.dayInEn) == date.bsDay }) else {
            return .empty
        }
        return WidgetToday(tithi: day.tithi ?? "", events: day.event == "--" ? "" : day.event)
    }

    private static func makeFestivals(from yearData: YearData, year: Int, on referenceDate: Date) -> [WidgetFestival] {
        let today = Calendar.nepal.startOfDay(for: referenceDate)
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

    private static func monthCalendarDays(for nepaliDate: NepaliDate, yearData: YearData?) -> [WidgetCalendarDay] {
        guard let daysInMonth = DateConverter.daysInMonth(year: nepaliDate.bsYear, month: nepaliDate.bsMonth),
              let firstGregorian = DateConverter.toGregorianDate(
                from: NepaliDate(bsYear: nepaliDate.bsYear, bsMonth: nepaliDate.bsMonth, bsDay: 1)
              ) else {
            return []
        }

        let firstWeekday = Calendar.nepal.component(.weekday, from: firstGregorian) // 1 = Sunday
        var days: [WidgetCalendarDay] = []
        var nextID = 0

        for _ in 0..<(firstWeekday - 1) {
            days.append(.placeholder(id: nextID))
            nextID += 1
        }

        for day in 1...daysInMonth {
            let dayNepali = NepaliDate(bsYear: nepaliDate.bsYear, bsMonth: nepaliDate.bsMonth, bsDay: day)
            let gregorian = DateConverter.toGregorianDate(from: dayNepali)
            let isSaturday = gregorian.map { Calendar.nepal.component(.weekday, from: $0) == 7 } ?? false
            let holidayFromData = yearData
                .flatMap { data in data.data.first(where: { $0.month == nepaliDate.bsMonth }) }
                .flatMap { month in month.days.first(where: { Int($0.dayInEn) == day }) }
                .map(\.isHoliday) ?? false

            days.append(
                WidgetCalendarDay(
                    id: nextID,
                    nepaliDay: NumberFormatter.nepaliString(from: day),
                    isToday: day == nepaliDate.bsDay,
                    isHoliday: isSaturday || holidayFromData,
                    isPlaceholder: false
                )
            )
            nextID += 1
        }

        while days.count % 7 != 0 {
            days.append(.placeholder(id: nextID))
            nextID += 1
        }

        return days
    }
}

struct MacPatroWidget: Widget {
    let kind = "MacPatroWidget.v2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacPatroWidgetProvider()) { entry in
            MacPatroWidgetView(entry: entry)
        }
        .configurationDisplayName("Mac Patro")
        .description("Nepali date with a mini month calendar.")
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
                MediumWidgetView(entry: entry)
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
            Text(Self.englishDateLabel(for: display))
                .font(.caption)
                .foregroundStyle(WidgetColors.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(display?.fullDateString ?? "Nepali date")
    }

    private static func englishDateLabel(for display: NepaliDateDisplay?) -> String {
        guard let display else { return DateConverter.formatEnglishDate(date: Date()) }
        // Format the wall-clock date in Nepal timezone so AD label matches the BS day.
        return DateConverter.formatEnglishDate(date: display.gregorianDate)
    }
}

private struct MediumWidgetView: View {
    let entry: MacPatroWidgetEntry

    private var display: NepaliDateDisplay? { entry.display }
    private var today: WidgetToday { entry.today }
    private let weekdayLabels = ["आ", "सो", "म", "बु", "बि", "शु", "श"]

    private var holidayColor: Color { Color(red: 0.85, green: 0.1, blue: 0.15) }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Match small widget hierarchy: weekday → day → month/year → tithi
            VStack(spacing: 4) {
                Text(display?.dayOfWeekName ?? "नेपाली पात्रो")
                    .font(.headline)
                    .foregroundStyle(entry.isHoliday ? holidayColor : WidgetColors.accent)
                    .lineLimit(1)
                Text(display?.dayString ?? "–")
                    .font(.system(size: 44, weight: .medium, design: .rounded))
                    .foregroundStyle(entry.isHoliday ? holidayColor : .primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("\(display?.monthName ?? "") \(display?.yearString ?? "")")
                    .font(.headline)
                    .foregroundStyle(entry.isHoliday ? holidayColor : .primary)
                    .lineLimit(1)
                if !today.tithi.isEmpty {
                    Text(today.tithi)
                        .font(.caption)
                        .foregroundStyle(WidgetColors.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)

            miniCalendar
                .frame(width: 150)
        }
        .padding(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(display?.fullDateString ?? "Nepali date")
    }

    private var miniCalendar: some View {
        let rows = stride(from: 0, to: entry.monthDays.count, by: 7).map { start in
            Array(entry.monthDays[start..<min(start + 7, entry.monthDays.count)])
        }

        return VStack(spacing: 3) {
            Text(display.map { "\($0.monthName) \($0.yearString)" } ?? "")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetColors.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 2) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(label == "श" ? holidayColor : WidgetColors.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 2) {
                    ForEach(row) { day in
                        Text(day.isPlaceholder ? " " : day.nepaliDay)
                            .font(.system(size: 9, weight: day.isToday ? .bold : .regular))
                            .foregroundStyle(miniDayColor(day))
                            .frame(maxWidth: .infinity, minHeight: 14)
                            .background {
                                if day.isToday {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.primary.opacity(0.14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .strokeBorder(
                                                    day.isHoliday ? holidayColor : WidgetColors.accent,
                                                    lineWidth: 1.2
                                                )
                                        )
                                }
                            }
                    }
                }
            }
        }
    }

    private func miniDayColor(_ day: WidgetCalendarDay) -> Color {
        if day.isPlaceholder { return .clear }
        // Avoid white-on-accent fills — they wash out when the desktop widget is inactive.
        if day.isToday { return day.isHoliday ? holidayColor : WidgetColors.accent }
        if day.isHoliday { return holidayColor }
        return .primary
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
