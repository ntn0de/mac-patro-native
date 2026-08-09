import Foundation

struct AppVersion {
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleGetInfoString") as? String ?? "1.0.12"
}
