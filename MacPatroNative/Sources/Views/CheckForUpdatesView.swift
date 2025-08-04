import SwiftUI

public struct CheckForUpdatesView: View {
    @ObservedObject private var updateService = UpdateService.shared
    
    private let instructionsURL = URL(string: "https://ntn0de.github.io/blog/mac-patro-app")!
    
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
        }
        .onAppear {
            updateService.checkForUpdates()
        }
    }
}
