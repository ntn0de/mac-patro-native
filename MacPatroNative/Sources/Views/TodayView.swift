import SwiftUI
import Combine

public struct TodayView: View {
    @ObservedObject var viewModel: TodayViewModel
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
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    public init(calendarViewModel: CalendarViewModel = CalendarViewModel()) {
        self.calendarViewModel = calendarViewModel
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

    public func fetchData(for date: Date = Date()) {
        let today = date
        let nepaliDate = DateConverter.gregorianToBikramSambat(date: today)
        self.nepaliDay = NumberFormatter.nepaliString(from: nepaliDate.bsDay)
        self.nepaliMonth = NepaliMonth(rawValue: nepaliDate.bsMonth)?.name ?? ""
        self.nepaliYear = NumberFormatter.nepaliString(from: nepaliDate.bsYear)
        
        let dayOfWeek = LocalizationService.shared.nepaliDay(for: nepaliDate.dayOfWeek)
        self.fullDateString = "\(dayOfWeek) \(self.nepaliDay), \(self.nepaliMonth) \(self.nepaliYear)"
        
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
        nepalTimeString = formatter.string(from: Date())
    }
    
    deinit {
        timer?.invalidate()
    }
}

