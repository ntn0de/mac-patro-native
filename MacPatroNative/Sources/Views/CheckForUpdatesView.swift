import SwiftUI
import AppKit

public struct CheckForUpdatesView: View {
    @ObservedObject private var updateService = UpdateService.shared
    
    private let instructionsURL = URL(string: "https://ntn0de.github.io/blog/mac-patro-app")!
    private let quarantineCommand = "xattr -cr /Applications/Mac\\ Patro.app"
     
    public var body: some View {
        VStack {
            Button {
                updateService.checkForUpdates()
            } label: {
                Label("Check for Updates", systemImage: "arrow.clockwise")
            }
            
            if !updateService.updateMessage.isEmpty {
                Text(updateService.updateMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let releaseURLString = updateService.releaseURL, let url = URL(string: releaseURLString) {
                HStack {
                    Link(destination: url) {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                    Link(destination: instructionsURL) {
                        Label("Instructions", systemImage: "questionmark.circle")
                    }
                }
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If macOS says Mac Patro is damaged, quit the app and run this in Terminal. After a Homebrew install, run it even if the app already launched:")
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
            .padding(.top, 4)
        }
        .onAppear {
            updateService.checkForUpdates()
        }
    }
}
