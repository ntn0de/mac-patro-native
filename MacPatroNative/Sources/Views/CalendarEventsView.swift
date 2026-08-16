import AppKit
import EventKit
import SwiftUI

struct CalendarEventsView: View {
    @Binding var rowCount: Int

    @State private var events: [CalendarEvent] = []
    @State private var displayedDate = Date()
    @State private var message = "Loading calendar events…"
    @State private var isBlinking = false
    @State private var isShowingDatePicker = false
    @State private var scrollTarget: String?
    private let eventStore = EKEventStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isShowingDatePicker = true
            } label: {
                Label(formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isShowingDatePicker, attachmentAnchor: .point(.bottomLeading), arrowEdge: .top) {
                DatePicker("", selection: $displayedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                    .focusable(false)
                    .padding()
            }

            if events.isEmpty {
                Text(message)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                        ForEach(events) { event in
                            Button {
                                openCalendar()
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        HStack(spacing: 4) {
                                            if event.showsLiveProgress {
                                                Circle()
                                                    .fill(.orange)
                                                    .frame(width: 7, height: 7)
                                                    .opacity(isBlinking ? 1 : 0.35)
                                            }
                                            Text(event.timeRange)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        if event.showsLiveProgress {
                                            ProgressView(value: event.progress)
                                                .progressViewStyle(.linear)
                                                .tint(event.color)
                                                .scaleEffect(y: 0.45)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 120, alignment: .trailing)
                                    Capsule()
                                        .fill(event.color)
                                        .frame(width: 4, height: event.timelineHeight)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title)
                                            .lineLimit(1)
                                        Text(event.calendarName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .opacity(event.isPast ? 0.45 : 1)
                            }
                            .buttonStyle(.plain)
                            .help(event.title)
                            .id(event.id)

                            if event.id != events.last?.id {
                                Divider()
                            }
                        }
                    }
                        .onAppear { scrollToTarget(using: proxy) }
                        .onChange(of: scrollTarget) { _ in scrollToTarget(using: proxy) }
                    }
                }
                .frame(maxHeight: 125)
            }
        }
        .padding(.horizontal, 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                isBlinking = true
            }
            refreshForToday()
        }
        .onChange(of: displayedDate) { _ in
            loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .calendarPopoverDidOpen)) { _ in
            refreshForToday()
        }
        .onReceive(DateChangeService.shared.dayDidChange) { _ in
            refreshForToday()
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: displayedDate)
    }

    private func refreshForToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(displayedDate, inSameDayAs: today) {
            displayedDate = today
        } else {
            requestAccessAndLoad()
        }
    }

    private func requestAccessAndLoad() {
        let completion: (Bool, Error?) -> Void = { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    message = "Calendar access was not granted."
                    return
                }
                loadEvents()
            }
        }

        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents(completion: completion)
        } else {
            eventStore.requestAccess(to: .event, completion: completion)
        }
    }

    private func loadEvents() {
        let start = Calendar.current.startOfDay(for: displayedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)

        events = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map(CalendarEvent.init)
        rowCount = events.count
        scrollTarget = events.first(where: \.isCurrent)?.id ?? events.first(where: { !$0.isPast })?.id
        message = "No calendar events for this day."
    }

    private func scrollToTarget(using proxy: ScrollViewProxy) {
        guard let scrollTarget else { return }
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(scrollTarget, anchor: .center)
            }
        }
    }

    private func openCalendar() {
        guard let calendarURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") else { return }
        NSWorkspace.shared.openApplication(at: calendarURL, configuration: .init())
    }
}

private struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let calendarName: String
    let timeRange: String
    let timelineHeight: CGFloat
    let color: Color
    let isCurrent: Bool
    let isPast: Bool
    let isAllDay: Bool
    let progress: Double

    var showsLiveProgress: Bool { isCurrent && !isAllDay }

    init(_ event: EKEvent) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        id = event.eventIdentifier ?? UUID().uuidString
        title = event.title ?? "Untitled Event"
        calendarName = event.calendar.title
        let range = event.isAllDay
            ? "All day"
            : "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
        isCurrent = Date() >= event.startDate && Date() < event.endDate
        isPast = event.endDate < Date()
        isAllDay = event.isAllDay
        timeRange = range
        let duration = event.endDate.timeIntervalSince(event.startDate)
        progress = duration > 0 ? min(max(Date().timeIntervalSince(event.startDate) / duration, 0), 1) : 0
        timelineHeight = event.isAllDay ? 22 : min(max(CGFloat(duration) / 120, 26), 56)
        color = Self.color(forCalendarName: event.calendar.title)
    }

    /// Stable, distinct accent per calendar account/email title.
    private static func color(forCalendarName name: String) -> Color {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var hash: UInt64 = 5381
        for byte in key.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }

        let hue = Double(hash % 360) / 360.0
        let saturation = 0.55 + Double((hash >> 9) % 25) / 100.0
        let brightness = 0.72 + Double((hash >> 17) % 18) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}
