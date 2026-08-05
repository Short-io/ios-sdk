import Testing
import Foundation
@testable import ShortIOSDK

/// Without `initialize(apiKey:domain:)`, network entry points must throw `.notInitialized`
/// rather than send an empty Authorization header.
struct InitializationTests {

    @Test func createShortLinkThrowsNotInitializedWhenInitializeNotCalled() async {
        let sdk = ShortIOSDK()
        do {
            _ = try await sdk.createShortLink(parameters: ShortIOParameters(originalURL: "https://example.com"))
            Issue.record("createShortLink should throw when the SDK is not initialized")
        } catch ShortIOError.notInitialized {
            // expected
        } catch {
            Issue.record("Expected .notInitialized, got \(error)")
        }
    }

    @Test func trackConversionThrowsNotInitializedWhenInitializeNotCalled() async {
        let sdk = ShortIOSDK()
        do {
            _ = try await sdk.trackConversion()
            Issue.record("trackConversion should throw when the SDK is not initialized")
        } catch ShortIOError.notInitialized {
            // expected
        } catch {
            Issue.record("Expected .notInitialized, got \(error)")
        }
    }
}
