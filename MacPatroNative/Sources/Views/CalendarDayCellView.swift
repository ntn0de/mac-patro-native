import SwiftUI

public struct CalendarDayCellView: View {
    let dayInfo: CalendarCellInfo
    @State private var isHovering = false
    @State private var showingPopover = false
    
    private var isToday: Bool { Calendar.current.isDateInToday(dayInfo.date) }
    // Only Saturday is a weekend holiday in Nepal
    private var isSaturday: Bool { Calendar.current.component(.weekday, from: dayInfo.date) == 7 }

    public init(dayInfo: CalendarCellInfo) {
        self.dayInfo = dayInfo
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(dayInfo.nepaliDay)
                .font(.title2)
                .fontWeight(isToday ? .bold : .regular)
            
            Text("\(dayInfo.englishDay)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 40, height: 40)
        .opacity(dayInfo.isCurrentMonth ? 1.0 : 0.2)
        .foregroundStyle(dayTextColor)
        .background(
            ZStack {
                if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(dayInfo.isHoliday ? Color(red: 0.85, green: 0.1, blue: 0.15) : Color.blue)
                        .opacity(dayInfo.isCurrentMonth ? 1.0 : 0.2)
                } else if isHovering {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                }
            }
        )
        .onHover { hovering in
            if dayInfo.isCurrentMonth {
                isHovering = hovering
            }
        }
        .onTapGesture {
            if dayInfo.event != nil || dayInfo.tithi != nil {
                showingPopover = true
            }
        }
        .popover(isPresented: $showingPopover) {
            VStack(alignment: .leading, spacing: 5) {
                if let tithi = dayInfo.tithi {
                    Text(tithi)
                        .fontWeight(.semibold)
                }
                if let event = dayInfo.event {
                    Text(event)
                }
            }
            .padding()
        }
    }
    
    private var dayTextColor: Color {
        if isToday {
            return .white
        }
        if isSaturday || dayInfo.isHoliday {
            return Color(red: 0.85, green: 0.1, blue: 0.15)
        } else {
            return .primary
        }
    }
}

struct CalendarDayCellView_Previews: PreviewProvider {
    static var previews: some View {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let weekend = Calendar.current.nextWeekend(startingAfter: today)!.start
        let prevMonthDay = Calendar.current.date(byAdding: .month, value: -1, to: today)!

        return ZStack {
//            Color.black.ignoresSafeArea()
            VStack {
                HStack {
                    CalendarDayCellView(dayInfo: .init(nepaliDay: "१", englishDay: 15, date: today, isCurrentMonth: true, isHoliday: true, event: "New Year", tithi: "प्रतिपदा"))
                    CalendarDayCellView(dayInfo: .init(nepaliDay: "२", englishDay: 16, date: tomorrow, isCurrentMonth: true, isHoliday: false, event: nil, tithi: "द्वितीया"))
                }
                HStack {
                    CalendarDayCellView(dayInfo: .init(nepaliDay: "३", englishDay: 17, date: weekend, isCurrentMonth: true, isHoliday: false, event: nil, tithi: "तृतीया"))
                    CalendarDayCellView(dayInfo: .init(nepaliDay: "४", englishDay: 18, date: prevMonthDay, isCurrentMonth: false, isHoliday: false, event: nil, tithi: "चतुर्थी"))
                }
            }
        }
//        .preferredColorScheme(.dark)
    }
}
