import SwiftUI

public struct MonthSwitcherView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    public init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.monthYearString)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(viewModel.englishMonthRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.goToPreviousMonth()
            }) {
                Image(systemName: "chevron.left")
                    .padding(5)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Button(action: {
                viewModel.goToNextMonth()
            }) {
                Image(systemName: "chevron.right")
                    .padding(5)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

struct MonthSwitcherView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MonthSwitcherView(viewModel: CalendarViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
