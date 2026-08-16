import AppKit
import SwiftUI

public struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    private let quarantineCommand = "xattr -cr /Applications/Mac\\ Patro.app"
    private let repositoryURL = URL(string: "https://github.com/ntn0de/mac-patro-native/")!

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Mac Patro")
                        .font(.title2.weight(.semibold))
                    Text("Nepali calendar for macOS")
                        .foregroundStyle(.secondary)
                    Text("Version \(AppVersion.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Label("Made by Saroj Subedi", systemImage: "person")
            Link(destination: repositoryURL) {
                Label("Open source on GitHub", systemImage: "arrow.up.right.square")
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If macOS blocks the app, run this in Terminal:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(quarantineCommand)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(quarantineCommand, forType: .string)
                    } label: {
                        Label("Copy Command", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            } label: {
                Label("Troubleshooting", systemImage: "wrench.and.screwdriver")
            }

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 380)
    }
}
