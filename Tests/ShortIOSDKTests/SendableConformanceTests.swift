import Testing
import Foundation
@testable import ShortIOSDK

/// Compiles only if `T` conforms to `Sendable`.
private func requireSendable<T: Sendable>(_ type: T.Type) {}

struct SendableConformanceTests {

    @Test func publicTypesAreSendable() {
        requireSendable(ShortIOResponse.self)
        requireSendable(ShortIOErrorResponse.self)
        requireSendable(User.self)
        requireSendable(ShortIOParameters.self)
        requireSendable(IntOrString.self)
        requireSendable(ShortIOResult.self)
        requireSendable(ShortIOError.self)
    }
}
