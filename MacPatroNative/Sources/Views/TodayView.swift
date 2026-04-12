import SwiftUI
import Combine
import AppKit

public struct TodayView: View {
    @ObservedObject private var viewModel: TodayViewModel
    @ObservedObject private var settings = SettingsService.shared

    public init(viewModel: TodayViewModel = TodayViewModel()) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Button(action: {
            viewModel.goToToday()
        }) {
            HStack(alignment: .center, spacing: 5) {
                VStack(alignment: .center, spacing: 1){
                    Text(viewModel.nepaliDay)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(viewModel.isHoliday ? Color(red: 0.85, green: 0.1, blue: 0.15) : .primary)
                        .lineLimit(1)
                    Text(viewModel.nepaliMonth)
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundStyle(viewModel.isHoliday ? Color(red: 0.85, green: 0.1, blue: 0.15) : .primary)
                }.padding(0)
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.fullDateString)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    if settings.showNepalTime {
                        Text(viewModel.nepalTimeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let tithi = viewModel.tithi {
                        Text(tithi)
                            .font(.headline)
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                    }
                    if let event = viewModel.event {
                        Text(event)
                            .font(.headline)
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                    }
                }.padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray.opacity(0.4)),
            alignment: .bottom
        )
        .onAppear {
            viewModel.onAppear()
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

#Preview("Today View") {
    let calendarViewModel = CalendarViewModel()
    let todayViewModel = TodayViewModel(calendarViewModel: calendarViewModel)
    todayViewModel.isHoliday = true
    todayViewModel.event = "This is a test event"
    return ZStack {
        Color.black.ignoresSafeArea()
        TodayView(viewModel: todayViewModel)
    }
    .preferredColorScheme(.dark)
}

public class TodayViewModel: ObservableObject {
    @ObservedObject private var settings = SettingsService.shared
    @Published public var nepaliDay: String = ""
    @Published public var nepaliMonth: String = ""
    @Published public var nepaliYear: String = ""
    @Published public var fullDateString: String = ""
    @Published public var isHoliday: Bool = false
    @Published public var event: String?
    @Published public var tithi: String?
    @Published public var nepalTimeString: String = ""

    private var calendarViewModel: CalendarViewModel
    private let calendarService: NepaliCalendarServing
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    public init(calendarViewModel: CalendarViewModel = CalendarViewModel(), calendarService: NepaliCalendarServing = NepaliCalendarService.shared) {
        self.calendarViewModel = calendarViewModel
        self.calendarService = calendarService
        fetchData()
        
        if settings.showNepalTime {
            updateNepalTime()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.updateNepalTime()
            }
        }
        
        // Subscribe to the centralized day change publisher
        DateChangeService.shared.dayDidChange
            .sink { [weak self] in
                #if DEBUG
                print("TodayViewModel received day change notification. Refreshing.")
                #endif
                self?.fetchData()
            }
            .store(in: &cancellables)

        // Subscribe to today's data changes from the calendar view model
        calendarViewModel.$todayYearData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                #if DEBUG
                print("TodayViewModel received todayYearData update. Refreshing.")
                #endif
                self?.fetchData()
            }
            .store(in: &cancellables)
    }

    public func fetchData(for date: Date? = nil) {
        let today = date ?? calendarService.currentDateForConversion
        guard let display = calendarService.display(for: today) else {
            self.nepaliDay = ""
            self.nepaliMonth = ""
            self.nepaliYear = ""
            self.fullDateString = DateConverter.formatEnglishDate(date: today)
            self.isHoliday = today.isSaturday()
            self.event = nil
            self.tithi = nil
            return
        }

        self.nepaliDay = display.dayString
        self.nepaliMonth = display.monthName
        self.nepaliYear = display.yearString
        self.fullDateString = display.fullDateString

        let info = calendarViewModel.getInfo(for: today)
        self.isHoliday = info.isHoliday
        self.event = info.event
        self.tithi = info.tithi
    }
    
    public func goToToday() {
        calendarViewModel.goToToday()
    }

    
    public func onAppear() {
        fetchData()
    }

    public func onDisappear() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateNepalTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss a 'NPT'"
        formatter.timeZone = TimeZone(identifier: "Asia/Kathmandu")
        let currentDate = Date()
        nepalTimeString = formatter.string(from: currentDate)
    }
    
    deinit {
        timer?.invalidate()
    }
}
