import Foundation

/// The SDK's mutable configuration, grouped so one lock guards one value.
struct Config: Sendable {
    var session: URLSession = .shared
    var isInitialized: Bool = false
    var apiKey: String = ""
    var domain: String = ""
    var clid: String = ""
}
