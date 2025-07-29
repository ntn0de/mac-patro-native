
import SwiftUI

public struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    public init() {}
    public var body: some View {
        VStack {
            Text("MacPatro")
                .font(.title)
            Text("Version 1.0.0")
                .font(.caption)
            Text("by Saroj Subedi")
                .font(.caption)
            Link("https://github.com/ntn0de/mac-patro-native/", destination: URL(string: "https://github.com/ntn0de/mac-patro-native/")!)
                .font(.caption)
            Spacer()
            Text("A simple Nepali calendar app for macOS.").multilineTextAlignment(.center)
            Spacer()
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 250, height: 200)
    }
}

