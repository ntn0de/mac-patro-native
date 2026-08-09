import SwiftUI

public struct DateConverterView: View {
    @State private var gregorianDate: Date
    @State private var nepaliYear: Int
    @State private var nepaliMonth: Int
    @State private var nepaliDay: Int
    @State private var isSynchronizingConverter = false

    public init(calendarService: NepaliCalendarServing = NepaliCalendarService.shared) {
        let initialNepaliDate = calendarService.currentNepaliDate() ?? NepaliDate(bsYear: DateConverter.supportedBSYearRange.lowerBound, bsMonth: 1, bsDay: 1)
        let initialGregorianDate = DateConverter.toGregorianDate(from: initialNepaliDate).map(Self.displayDate(fromConversionDate:)) ?? Date()

        _gregorianDate = State(initialValue: initialGregorianDate)
        _nepaliYear = State(initialValue: initialNepaliDate.bsYear)
        _nepaliMonth = State(initialValue: initialNepaliDate.bsMonth)
        _nepaliDay = State(initialValue: initialNepaliDate.bsDay)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AD")
                    .frame(width: 24, alignment: .leading)
                DatePicker("", selection: $gregorianDate, displayedComponents: .date)
                    .labelsHidden()
                Spacer()
                Button {
                    gregorianDate = Self.displayDate(fromConversionDate: Calendar.currentDateForNepalConversion)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .help("Today")
            }

            Divider()

            HStack(spacing: 8) {
                Text("BS")
                    .frame(width: 24, alignment: .leading)
                Stepper(value: $nepaliYear, in: DateConverter.supportedBSYearRange) {
                    Text(NumberFormatter.nepaliString(from: nepaliYear))
                        .frame(width: 52, alignment: .leading)
                }
                Picker("Month", selection: $nepaliMonth) {
                    ForEach(NepaliMonth.allCases, id: \.rawValue) { month in
                        Text(month.name).tag(month.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 120)

                Picker("Day", selection: $nepaliDay) {
                    ForEach(1...daysInSelectedNepaliMonth, id: \.self) { day in
                        Text(NumberFormatter.nepaliString(from: day)).tag(day)
                    }
                }
                .labelsHidden()
                .frame(width: 48)
            }

            Divider()

            Text("\(formattedGregorianDate)  ↔  \(formattedNepaliDate)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding()
        .frame(width: 380)
        .onAppear {
            syncNepaliFromGregorian()
        }
        .onChange(of: gregorianDate) { _ in
            syncNepaliFromGregorian()
        }
        .onChange(of: nepaliYear) { _ in
            syncGregorianFromNepali()
        }
        .onChange(of: nepaliMonth) { _ in
            syncGregorianFromNepali()
        }
        .onChange(of: nepaliDay) { _ in
            syncGregorianFromNepali()
        }
    }

    private var daysInSelectedNepaliMonth: Int {
        DateConverter.daysInMonth(year: nepaliYear, month: nepaliMonth) ?? 30
    }

    private var formattedGregorianDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter.string(from: gregorianDate)
    }

    private var formattedNepaliDate: String {
        let monthName = NepaliMonth(rawValue: nepaliMonth)?.name ?? ""
        return "\(monthName) \(NumberFormatter.nepaliString(from: nepaliDay)), \(NumberFormatter.nepaliString(from: nepaliYear))"
    }

    private func syncNepaliFromGregorian() {
        guard !isSynchronizingConverter else { return }
        isSynchronizingConverter = true
        defer { isSynchronizingConverter = false }

        let gregorianComponents = Self.gregorianCalendar.dateComponents([.year, .month, .day], from: gregorianDate)
        var utcComponents = DateComponents()
        utcComponents.calendar = Self.utcGregorianCalendar
        utcComponents.timeZone = TimeZone(secondsFromGMT: 0)
        utcComponents.year = gregorianComponents.year
        utcComponents.month = gregorianComponents.month
        utcComponents.day = gregorianComponents.day

        guard let conversionDate = Self.utcGregorianCalendar.date(from: utcComponents),
              let nepaliDate = DateConverter.toNepaliDate(from: conversionDate) else {
            return
        }

        nepaliYear = nepaliDate.bsYear
        nepaliMonth = nepaliDate.bsMonth
        nepaliDay = nepaliDate.bsDay
    }

    private func syncGregorianFromNepali() {
        guard !isSynchronizingConverter else { return }
        isSynchronizingConverter = true
        defer { isSynchronizingConverter = false }

        let clampedDay = min(nepaliDay, daysInSelectedNepaliMonth)
        if nepaliDay != clampedDay {
            nepaliDay = clampedDay
        }

        guard let conversionDate = DateConverter.toGregorianDate(from: NepaliDate(bsYear: nepaliYear, bsMonth: nepaliMonth, bsDay: clampedDay)) else {
            return
        }

        gregorianDate = Self.displayDate(fromConversionDate: conversionDate)
    }

    private static func displayDate(fromConversionDate date: Date) -> Date {
        let components = utcGregorianCalendar.dateComponents([.year, .month, .day], from: date)
        return gregorianCalendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: 12)) ?? date
    }

    private static let gregorianCalendar = Calendar(identifier: .gregorian)
    private static var utcGregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }
}

#Preview {
    DateConverterView()
}
