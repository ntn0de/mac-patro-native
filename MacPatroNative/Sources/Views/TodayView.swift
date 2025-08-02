import SwiftUI
import Combine

public struct TodayView: View {
    @ObservedObject var viewModel: TodayViewModel

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
            viewModel.fetchData()
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
    @Published public var nepaliDay: String = ""
    @Published public var nepaliMonth: String = ""
    @Published public var nepaliYear: String = ""
    @Published public var fullDateString: String = ""
    @Published public var isHoliday: Bool = false
    @Published public var event: String?
    @Published public var tithi: String?

    private var calendarViewModel: CalendarViewModel
    private var cancellables = Set<AnyCancellable>()

    public init(calendarViewModel: CalendarViewModel = CalendarViewModel()) {
        self.calendarViewModel = calendarViewModel
        fetchData()
        
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
        let nepaliDate = DateConverter.gregorianToBikramSambat(date: date)
        self.nepaliDay = NumberFormatter.nepaliString(from: nepaliDate.bsDay)
        self.nepaliMonth = NepaliMonth(rawValue: nepaliDate.bsMonth)?.name ?? ""
        self.nepaliYear = NumberFormatter.nepaliString(from: nepaliDate.bsYear)
        
        let dayOfWeek = LocalizationService.shared.nepaliDay(for: nepaliDate.dayOfWeek)
        self.fullDateString = "\(dayOfWeek) \(self.nepaliDay), \(self.nepaliMonth) \(self.nepaliYear)"
        
        self.isHoliday = calendarViewModel.isHolidayOrSaturday(date: date)
        self.event = calendarViewModel.event(for: date)
        self.tithi = calendarViewModel.tithi(for: date)
    }
    
    public func goToToday() {
        calendarViewModel.goToToday()
    }
}

