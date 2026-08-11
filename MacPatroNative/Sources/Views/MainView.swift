import SwiftUI
import AppKit

extension Notification.Name {
    public static let calendarPopoverDidOpen = Notification.Name("calendarPopoverDidOpen")
    public static let calendarPopoverDidClose = Notification.Name("calendarPopoverDidClose")
    public static let popoverContentHeightDidChange = Notification.Name("popoverContentHeightDidChange")
}

private struct PopoverContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
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
    @State private var isEventPanelExpanded = true
    
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
            Color.clear.frame(height: 8)
            Divider()
            HStack(spacing: 12) {
                Button("Events") {
                    selectedSection = .events
                    isEventPanelExpanded = true
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selectedSection == .events ? Color.gray.opacity(0.25) : .clear, in: Capsule())
                .foregroundStyle(selectedSection == .events ? .primary : .secondary)

                Button("Calendar") {
                    selectedSection = .calendar
                    isEventPanelExpanded = true
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selectedSection == .calendar ? Color.gray.opacity(0.25) : .clear, in: Capsule())
                .foregroundStyle(selectedSection == .calendar ? .primary : .secondary)

                Spacer(minLength: 0)

                Button {
                    isEventPanelExpanded.toggle()
                } label: {
                    Image(systemName: isEventPanelExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isEventPanelExpanded ? "Collapse" : "Expand")
                .accessibilityLabel(isEventPanelExpanded ? "Collapse events" : "Expand events")
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }

            if isEventPanelExpanded {
                Group {
                    if selectedSection == .events {
                        EventsView(viewModel: viewModel)
                    } else {
                        CalendarEventsView(rowCount: $calendarEventRowCount)
                    }
                }
                .frame(width: 328, height: eventPanelHeight, alignment: .topLeading)
            }

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
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 360)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: PopoverContentHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(PopoverContentHeightKey.self) { height in
            guard height > 0 else { return }
            NotificationCenter.default.post(
                name: .popoverContentHeightDidChange,
                object: nil,
                userInfo: ["height": height]
            )
        }
        .onAppear {
            updateService.checkForUpdates()
            presentNewYearGreetingIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .calendarPopoverDidOpen)) { _ in
            DateChangeService.shared.publishIfDayChanged()
            viewModel.goToToday()
            todayViewModel.fetchData()
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
            MainView()
        }
    }
}
