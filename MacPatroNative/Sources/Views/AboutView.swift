
import SwiftUI

public struct AboutView: View {
    public init() {}
    public var body: some View {
        VStack {
            Text("MacPatro Native")
                .font(.title)
            Text("Version 1.0.0")
                .font(.caption)
            Text("by Saroj Subedi")
                .font(.caption)
            Link("https://github.com/ntn0de", destination: URL(string: "https://github.com/ntn0de")!)
                .font(.caption)
            Spacer()
            Text("A simple Nepali calendar app for macOS.")
            Spacer()
        }
        .padding()
        .frame(width: 200, height: 100)
    }
}

