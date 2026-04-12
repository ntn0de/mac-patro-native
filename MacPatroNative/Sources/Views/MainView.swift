import SwiftUI
import AppKit

extension Notification.Name {
    public static let calendarPopoverDidOpen = Notification.Name("calendarPopoverDidOpen")
    public static let calendarPopoverDidClose = Notification.Name("calendarPopoverDidClose")
}

public struct MainView: View {
    @StateObject private var viewModel: CalendarViewModel
    @StateObject private var todayViewModel: TodayViewModel
    @ObservedObject private var updateService = UpdateService.shared
    @State private var showUpdateBadge = false
    @State private var showNewYearGreeting = false
    @State private var displayedNewYearGreetingYear: Int?
    
    private let calendarService: NepaliCalendarServing
    private let settingsWindowController = SettingsWindowController()
    private let updateDismissedKey = "updateDismissed"
    private let newYearGreetingYearKey = "lastShownNewYearGreetingBSYear"
    
    public init(calendarService: NepaliCalendarServing = NepaliCalendarService.shared) {
        self.calendarService = calendarService
        let calendarViewModel = CalendarViewModel(calendarService: calendarService)
        _viewModel = StateObject(wrappedValue: calendarViewModel)
        _todayViewModel = StateObject(wrappedValue: TodayViewModel(calendarViewModel: calendarViewModel, calendarService: calendarService))
    }

    public func forceRefresh() {
        viewModel.forceRefresh()
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            if showUpdateBadge {
                UpdateBadgeView(onDismiss: {
                    UserDefaults.standard.set(Date(), forKey: updateDismissedKey)
                    showUpdateBadge = false
                })
                .onTapGesture {
                    settingsWindowController.openSettings()
                }
            }
            if showNewYearGreeting, let greetingYear = displayedNewYearGreetingYear {
                NewYearGreetingBannerView(
                    nepaliYearText: NumberFormatter.nepaliString(from: greetingYear),
                    englishYearText: String(greetingYear)
                ) {
                    withAnimation {
                        showNewYearGreeting = false
                        displayedNewYearGreetingYear = nil
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            TodayView(viewModel: todayViewModel)
            MonthSwitcherView(viewModel: viewModel)
            CalendarGridView(viewModel: viewModel)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
        .frame(maxWidth: 360)
        .onAppear {
            updateService.checkForUpdates()
            presentNewYearGreetingIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .calendarPopoverDidOpen)) { _ in
            updateService.checkForUpdates()
            presentNewYearGreetingIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .calendarPopoverDidClose)) { _ in
            withAnimation {
                showNewYearGreeting = false
                displayedNewYearGreetingYear = nil
            }
        }
        .onReceive(updateService.$updateAvailable) { updateAvailable in
            if updateAvailable {
                let lastDismissed = UserDefaults.standard.object(forKey: updateDismissedKey) as? Date
                if let lastDismissed = lastDismissed {
                    if Date().timeIntervalSince(lastDismissed) > 24 * 60 * 60 {
                        self.showUpdateBadge = true
                    }
                } else {
                    self.showUpdateBadge = true
                }
            }
        }
    }

    private func presentNewYearGreetingIfNeeded() {
        guard let nepaliDate = calendarService.currentNepaliDate(),
              nepaliDate.bsMonth == NepaliMonth.Baisakh.rawValue,
              nepaliDate.bsDay == 1 else {
            return
        }

        let lastShownYear = UserDefaults.standard.integer(forKey: newYearGreetingYearKey)
        guard lastShownYear != nepaliDate.bsYear else {
            return
        }

        UserDefaults.standard.set(nepaliDate.bsYear, forKey: newYearGreetingYearKey)

        withAnimation {
            displayedNewYearGreetingYear = nepaliDate.bsYear
            showNewYearGreeting = true
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
//            Color.black.ignoresSafeArea()
            MainView()
        }
    }
}
