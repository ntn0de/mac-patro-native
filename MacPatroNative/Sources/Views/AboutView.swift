
import SwiftUI
import AppKit

public struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    private let quarantineCommand = "xattr -cr /Applications/Mac\\ Patro.app"

    public init() {}
    public var body: some View {
        VStack {
            Text("MacPatro")
                .font(.title)
            Text("Version \(AppVersion.version)")
                .font(.caption)
            Text("by Saroj Subedi")
                .font(.caption)
            Link("https://github.com/ntn0de/mac-patro-native/", destination: URL(string: "https://github.com/ntn0de/mac-patro-native/")!)
                .font(.caption)
            Spacer()
            Text("A simple Nepali calendar app for macOS.").multilineTextAlignment(.center)
            DisclosureGroup("If macOS blocks opening") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Run this command in Terminal:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(quarantineCommand)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    Button("Copy Command") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(quarantineCommand, forType: .string)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            Spacer()
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 320, height: 260)
    }
}
