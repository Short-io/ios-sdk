import Testing
import Foundation
@testable import ShortIOSDK

/// Smoke coverage that error mapping survived the rewrite of `handleClick` from
/// `dataTask` + `DispatchQueue.main.async` to `async`/`await`.
struct URLHandlerTests {

    private func makeComponents(_ string: String) throws -> URLComponents {
        let handler = URLHandler(session: URLProtocolStub.session())
        return try handler.createURLComponents(from: URL(string: string)!)
    }

    @Test func notFoundMapsToLinkNotValid() async throws {
        URLProtocolStub.register(.init(statusCode: 404, url: URL(string: "https://example.com/click/missing")!))
        let handler = URLHandler(session: URLProtocolStub.session())
        let components = try makeComponents("https://example.com/click/missing")

        await #expect(throws: URLHandlerError.self) {
            try await handler.handleClick(urlComponents: components)
        }
    }

    /// A 404 reached *after* a redirect belongs to the destination, not to the short link.
    /// Reporting it as `.linkNotValid` sends callers hunting for a bad short link that is fine.
    @Test func notFoundAfterRedirectMapsToDestinationUnavailable() async throws {
        let shortLink = URL(string: "https://example.com/click/live")!
        let destination = URL(string: "https://example.com/your/long/url?clid=abc")!
        // responseURL is the post-redirect URL, which is what URLSession surfaces once it
        // has followed the shortener's 302.
        URLProtocolStub.register(.init(statusCode: 404, url: shortLink, responseURL: destination))
        let handler = URLHandler(session: URLProtocolStub.session())
        let components = try makeComponents(shortLink.absoluteString)

        do {
            _ = try await handler.handleClick(urlComponents: components)
            Issue.record("expected handleClick to throw")
        } catch let error as URLHandlerError {
            guard case .destinationUnavailable(let statusCode, let url) = error else {
                Issue.record("expected .destinationUnavailable, got \(error)")
                return
            }
            #expect(statusCode == 404)
            #expect(url == destination)
        }
    }

    /// `URLSession` reports task cancellation as `URLError(.cancelled)`. It must surface as
    /// `CancellationError`, not be flattened into `.networkError` alongside real failures.
    @Test func cancellationIsNotReportedAsANetworkError() async throws {
        let url = URL(string: "https://example.com/click/cancelled")!
        URLProtocolStub.register(.init(url: url, error: URLError(.cancelled)))
        let handler = URLHandler(session: URLProtocolStub.session())
        let components = try makeComponents(url.absoluteString)

        await #expect(throws: CancellationError.self) {
            try await handler.handleClick(urlComponents: components)
        }
    }

    /// A genuine transport failure still maps to `.networkError`.
    @Test func transportFailureMapsToNetworkError() async throws {
        let url = URL(string: "https://example.com/click/offline")!
        URLProtocolStub.register(.init(url: url, error: URLError(.notConnectedToInternet)))
        let handler = URLHandler(session: URLProtocolStub.session())
        let components = try makeComponents(url.absoluteString)

        do {
            _ = try await handler.handleClick(urlComponents: components)
            Issue.record("expected handleClick to throw")
        } catch let error as URLHandlerError {
            guard case .networkError = error else {
                Issue.record("expected .networkError, got \(error)")
                return
            }
        }
    }
}
