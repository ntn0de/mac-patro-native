import SwiftUI
import AppKit

public struct CheckForUpdatesView: View {
    @ObservedObject private var updateService = UpdateService.shared
    
    private let instructionsURL = URL(string: "https://ntn0de.github.io/blog/mac-patro-app")!
    private let quarantineCommand = "xattr -cr /Applications/Mac\\ Patro.app"
     
    public var body: some View {
        VStack {
            Button("Check for Updates") {
                updateService.checkForUpdates()
            }
            
            if !updateService.updateMessage.isEmpty {
                Text(updateService.updateMessage)
                    .padding()
            }
            
            if let releaseURLString = updateService.releaseURL, let url = URL(string: releaseURLString) {
                HStack {
                    Link("Download", destination: url)
                    Text(" | ")
                    Link("Instructions", destination: instructionsURL)
                }
            }

            DisclosureGroup("Troubleshooting") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If macOS says Mac Patro is damaged or should be moved to the Trash, run this in Terminal:")
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
            .padding(.top, 8)
        }
        .onAppear {
            updateService.checkForUpdates()
        }
    }
}
