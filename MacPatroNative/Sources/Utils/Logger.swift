import Foundation

/// A custom logging function that only prints to the console in DEBUG builds.
/// - Parameter items: The items to be printed, same as the standard `print` function.
func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
    #endif
}
