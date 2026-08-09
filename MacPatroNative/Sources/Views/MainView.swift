import SwiftUI
import AppKit

extension Notification.Name {
    public static let calendarPopoverDidOpen = Notification.Name("calendarPopoverDidOpen")
    public static let calendarPopoverDidClose = Notification.Name("calendarPopoverDidClose")
    public static let eventPanelHeightDidChange = Notification.Name("eventPanelHeightDidChange")
}

public struct MainView: View {
    @StateObject private var viewModel: CalendarViewModel
    @StateObject private var todayViewModel: TodayViewModel
    @ObservedObject private var updateService = UpdateService.shared
    @State private var showUpdateBadge = false
    @State private var showNewYearGreeting = false
    @State private var displayedNewYearGreetingYear: Int?
    @State private var selectedSection = CalendarSection.events
    @State private var calendarEventRowCount = 0
    
    private let calendarService: NepaliCalendarServing
    private let settingsWindowController = SettingsWindowController()
    private let dateConverterWindowController = DateConverterWindowController()
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
            Spacer(minLength: 8)
            Divider()
            HStack(spacing: 12) {
                Button("Events") {
                    selectedSection = .events
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selectedSection == .events ? Color.gray.opacity(0.25) : .clear, in: Capsule())
                .foregroundStyle(selectedSection == .events ? .primary : .secondary)

                Button("Calendar") {
                    selectedSection = .calendar
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selectedSection == .calendar ? Color.gray.opacity(0.25) : .clear, in: Capsule())
                .foregroundStyle(selectedSection == .calendar ? .primary : .secondary)

                Spacer()
            }

            Group {
                if selectedSection == .events {
                    EventsView(viewModel: viewModel)
                } else {
                    CalendarEventsView(rowCount: $calendarEventRowCount)
                }
            }
            .frame(width: 328, height: eventPanelHeight, alignment: .topLeading)
            .onAppear(perform: reportPanelHeight)
            .onChange(of: calendarEventRowCount) { _ in reportPanelHeight() }
            .onChange(of: viewModel.upcomingEvents().count) { _ in reportPanelHeight() }
            HStack(spacing: 14) {
                Spacer()
                Button {
                    dateConverterWindowController.openDateConverter()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                }
                .buttonStyle(.plain)
                .help("Date Converter")

                Button {
                    settingsWindowController.openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
        .frame(maxWidth: 360)
        .onAppear {
            updateService.checkForUpdates()
            presentNewYearGreetingIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .calendarPopoverDidOpen)) { _ in
            viewModel.goToToday()
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

    private var eventPanelHeight: CGFloat {
        let eventHeight = max(viewModel.upcomingEvents().count, 1) * 43
        let calendarHeight = calendarEventRowCount == 0 ? 43 : min(calendarEventRowCount, 3) * 42 + 34
        return CGFloat(max(eventHeight, calendarHeight))
    }

    private func reportPanelHeight() {
        NotificationCenter.default.post(
            name: .eventPanelHeightDidChange,
            object: nil,
            userInfo: ["height": eventPanelHeight]
        )
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

private enum CalendarSection {
    case events
    case calendar
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
//            Color.black.ignoresSafeArea()
            MainView()
        }
    }
}
