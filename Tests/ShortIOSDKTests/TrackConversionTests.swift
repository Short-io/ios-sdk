import Testing
import Foundation
@testable import ShortIOSDK

/// Covers the premise of the new `trackConversion(conversionId:)` overload: the `clid` no
/// longer has to be passed, because `handleOpen(_:)` records it.
struct TrackConversionTests {

    private func conversionURL(domain: String) -> URL {
        URL(string: "https://\(domain)/.shortio/conversion")!
    }

    @Test func usesClidCapturedByHandleOpenWhenNoneIsPassed() async throws {
        let domain = "capture.example"
        let landingURL = URL(string: "https://\(domain)/landing?clid=stored-clid")!
        // The click request during handleOpen.
        URLProtocolStub.register(.init(statusCode: 200, url: landingURL))
        // The conversion request afterwards.
        URLProtocolStub.register(.init(statusCode: 200, url: conversionURL(domain: domain)))

        let sdk = ShortIOSDK()
        sdk.initialize(session: URLProtocolStub.session(), apiKey: "sk_test_key", domain: domain)

        _ = try await sdk.handleOpen(URL(string: "https://\(domain)/landing")!)

        let succeeded = try await sdk.trackConversion()

        let captured = try #require(URLProtocolStub.capturedRequest(for: conversionURL(domain: domain)))
        #expect(captured.url?.query?.contains("clid=stored-clid") == true)
        #expect(succeeded)
    }

    /// Regression for #5: `conversionId` (and `clid`) must be percent-encoded, so reserved
    /// characters cannot break out of their query slot.
    @Test func conversionIdAndClidArePercentEncoded() async throws {
        let domain = "encode.example"
        URLProtocolStub.register(.init(statusCode: 200, url: conversionURL(domain: domain)))

        let sdk = ShortIOSDK()
        sdk.initialize(session: URLProtocolStub.session(), apiKey: "sk_test_key", domain: domain)
        sdk.setClidForTesting("stored clid") // space must be encoded

        _ = try await sdk.trackConversion(conversionId: "a&b=c") // all reserved

        let captured = try #require(URLProtocolStub.capturedRequest(for: conversionURL(domain: domain)))
        let query = try #require(captured.url?.query)
        // clid value "stored clid" must not appear raw; its encoded form must.
        #expect(query.contains("clid=stored%20clid"))
        #expect(query.contains("c=a%26b%3Dc"))
        // The raw reserved characters must not leak through.
        #expect(!query.contains("clid=stored clid"))
        #expect(!query.contains("&c=a&b=c"))
    }
}
