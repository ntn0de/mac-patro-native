
import SwiftUI

public struct SettingsView: View {
    @AppStorage("dateFormat") private var selectedFormat: Int = 0
    let dateFormats = ["D-Month", "YYYY-MM-DD", "Month D, YYYY"]
    
    public init() {}

    public var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
            
            Picker("Date Format", selection: $selectedFormat) {
                ForEach(0..<dateFormats.count, id: \.self) {
                    Text(self.dateFormats[$0])
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}
