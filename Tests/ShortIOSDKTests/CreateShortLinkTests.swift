import Testing
import Foundation
@testable import ShortIOSDK

/// Serialized: every test posts to the same endpoint, and `URLProtocolStub` keys its registry
/// by host + path, so parallel runs would overwrite each other's stubs.
@Suite(.serialized)
struct CreateShortLinkTests {

    /// The single endpoint all create-link requests hit.
    private let endpoint = URL(string: "https://api.short.io/links/public")!

    /// A minimal valid success body — enough for `ShortIOResponse` to decode.
    private func successBody() throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "originalURL": "https://long.example/page",
            "path": "/abc",
            "idString": "id-str",
            "id": "abc",
            "shortURL": "https://example.com/abc",
            "secureShortURL": "https://example.com/secure",
            "cloaking": false,
            "tags": [],
            "createdAt": "2024-01-01T00:00:00Z",
            "skipQS": false,
            "archived": false,
            "DomainId": 42,
            "OwnerId": 7,
            "hasPassword": false,
            "source": "api",
            "success": true,
            "duplicate": false
        ])
    }

    @Test func parametersWithoutDomainFallBackToConfiguredDomain() async throws {
        URLProtocolStub.register(.init(statusCode: 200, url: endpoint, body: try successBody()))

        let sdk = ShortIOSDK()
        sdk.initialize(session: URLProtocolStub.session(), apiKey: "sk_test_key", domain: "configured.example")

        _ = try await sdk.createShortLink(parameters: ShortIOParameters(originalURL: "https://long.example/page"))

        let captured = try #require(URLProtocolStub.capturedRequest(for: endpoint))
        let body = try #require(captured.body)
        let json = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        #expect(json["domain"] as? String == "configured.example")
    }

    /// Body captured verbatim from the live API for `"domain": ""`. The SDK must forward it
    /// rather than substitute an error of its own.
    @Test func serverDomainValidationErrorIsForwardedVerbatim() async throws {
        URLProtocolStub.register(.init(
            statusCode: 400,
            url: endpoint,
            body: Data(#"{"message":"domain must match format \"hostname\"","statusCode":400,"code":"FST_ERR_VALIDATION","success":false}"#.utf8)
        ))

        let sdk = ShortIOSDK()
        sdk.initialize(session: URLProtocolStub.session(), apiKey: "sk_test_key", domain: "")

        let result = try await sdk.createShortLink(
            parameters: ShortIOParameters(originalURL: "https://long.example/page")
        )

        guard case .failure(let error) = result else {
            Issue.record("expected .failure, got \(result)")
            return
        }
        #expect(error.statusCode == 400)
        #expect(error.message == #"domain must match format "hostname""#)
        // The server's error code must survive — a locally synthesised failure would drop it.
        #expect(error.code == "FST_ERR_VALIDATION")
    }

    /// A non-JSON error body must still surface as a structured failure rather than throwing.
    @Test func nonJSONErrorBodyFallsBackToStatusCodeFailure() async throws {
        URLProtocolStub.register(.init(
            statusCode: 502,
            url: endpoint,
            body: Data("<html><body>Bad Gateway</body></html>".utf8)
        ))

        let sdk = ShortIOSDK()
        sdk.initialize(session: URLProtocolStub.session(), apiKey: "sk_test_key", domain: "configured.example")

        let result = try await sdk.createShortLink(
            parameters: ShortIOParameters(originalURL: "https://long.example/page")
        )

        guard case .failure(let error) = result else {
            Issue.record("expected .failure, got \(result)")
            return
        }
        #expect(error.statusCode == 502)
    }
}
