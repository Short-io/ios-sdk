import Testing
import Foundation
@testable import ShortIOSDK

struct ConcurrencyTests {

    /// Compiles only if `ShortIOSDK` is `Sendable` — the property consumers need.
    @Test func sdkIsSendable() {
        func requireSendable<T: Sendable>(_ type: T.Type) {}
        requireSendable(ShortIOSDK.self)
    }

    @Test func concurrentConfigurationAccessIsRaceFree() async {
        let sdk = ShortIOSDK()
        sdk.initialize(session: URLProtocolStub.session(), apiKey: "key", domain: "example.com")

        // Many tasks reading and writing the same storage simultaneously.
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<200 {
                group.addTask {
                    if index.isMultiple(of: 2) {
                        sdk.setClidForTesting("clid-\(index)")
                    } else {
                        _ = sdk.clidForTesting
                    }
                }
            }
        }

        #expect(sdk.clidForTesting.hasPrefix("clid-"))
    }

    @Test func initializeIsAppliedOnlyOnce() {
        let sdk = ShortIOSDK()

        sdk.initialize(apiKey: "first", domain: "first.example")
        sdk.initialize(apiKey: "second", domain: "second.example")

        #expect(sdk.apiKeyForTesting == "first")
        #expect(sdk.domainForTesting == "first.example")
    }
}
