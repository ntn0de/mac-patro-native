import SwiftUI

struct EventsView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var selectedEvent: UpcomingEvent?

    var body: some View {
        let events = viewModel.upcomingEvents()

        Group {
            if events.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.title)
                Text("No upcoming events")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                ForEach(events) { event in
                    Button {
                        selectedEvent = event
                    } label: {
                        HStack(spacing: 10) {
                            Capsule()
                                .fill(.red.opacity(0.7))
                                .frame(width: 4, height: 26)
                            Text(event.title)
                                .lineLimit(1)
                            Spacer()
                            Text("\(NumberFormatter.nepaliString(from: event.daysRemaining)) दिन")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .help(event.tooltip)
                    .popover(
                        isPresented: Binding(
                            get: { selectedEvent?.id == event.id },
                            set: { if !$0 { selectedEvent = nil } }
                        ),
                        attachmentAnchor: .point(.bottomLeading),
                        arrowEdge: .top
                    ) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(event.title)
                                .fontWeight(.semibold)
                            Text(event.tooltip)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    if event.id != events.last?.id {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            }
        }
    }
}
