import Foundation

public class UpdateService: ObservableObject {
    
    public static let shared = UpdateService()
    
    private let owner = "ntn0de"
    private let repo = "mac-patro-native"
    
    @Published public var updateAvailable: Bool = false
    @Published public var updateMessage = ""
    @Published public var releaseURL: String?
    
    private init() {}
    
    public func checkForUpdates() {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.updateMessage = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.updateMessage = "Error: No data received"
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                    let htmlURL = json["html_url"] as? String {
                    var latestVersion = tagName
                    if latestVersion.hasPrefix("v") {
                        latestVersion.removeFirst()
                    }
                    
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.9"
                    
                    if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            self.updateAvailable = true
                            self.updateMessage = "You have v\(currentVersion). Version \(latestVersion) is available."
                            self.releaseURL = htmlURL
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.updateMessage = "You are up-to-date (v\(currentVersion))."
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
}
