import SwiftUI

public struct CalendarGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)
    private let dayOfWeekLabels = ["आइत", "सोम", "मङ्गल", "बुध", "बिहि", "शुक्र", "शनि"]

    public init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(dayOfWeekLabels, id: \.self) { dayLabel in
                    Text(dayLabel)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(red: 0.85, green: 0.1, blue: 0.15))
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(viewModel.days, id: \.self) { dayInfo in
                    CalendarDayCellView(dayInfo: dayInfo)
                }
            }
        }
    }
}

struct CalendarGridView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CalendarGridView(viewModel: CalendarViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
