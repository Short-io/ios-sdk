import Foundation

/// A `URLProtocol` returning canned responses, so tests never touch the network.
///
/// Stubs are keyed by host + path rather than a single global slot, so tests running in
/// parallel don't overwrite each other. Requests are recorded for assertions.
final class URLProtocolStub: URLProtocol, @unchecked Sendable {

    struct Stub {
        let statusCode: Int
        let url: URL
        /// The URL the response reports, when it differs from the one requested. `URLSession`
        /// follows redirects transparently, so this is how a post-redirect response is modelled.
        let responseURL: URL?
        let body: Data?
        let error: Error?

        init(statusCode: Int = 200, url: URL, responseURL: URL? = nil, body: Data? = nil, error: Error? = nil) {
            self.statusCode = statusCode
            self.url = url
            self.responseURL = responseURL
            self.body = body
            self.error = error
        }
    }

    /// A snapshot of a request the protocol received, for assertions.
    struct CapturedRequest: Sendable {
        let url: URL?
        let headers: [String: String]
        let body: Data?
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var stubsByKey: [String: Stub] = [:]
    nonisolated(unsafe) private static var capturedByKey: [String: CapturedRequest] = [:]

    /// Registers a canned response, served for any request matching `stub.url`'s host + path.
    static func register(_ stub: Stub) {
        lock.lock(); defer { lock.unlock() }
        stubsByKey[key(for: stub.url)] = stub
    }

    /// The most recent request seen for `url`'s host + path, or `nil` if none was served.
    static func capturedRequest(for url: URL) -> CapturedRequest? {
        lock.lock(); defer { lock.unlock() }
        return capturedByKey[key(for: url)]
    }

    /// A session wired to this protocol. Pass to `ShortIOSDK.initialize(session:apiKey:domain:)`.
    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    // MARK: - Keying

    /// Excludes the query, which the SDK appends to (`utm_medium`, `clid`, `c`).
    private static func key(for url: URL) -> String { "\(url.host ?? "")\(url.path)" }

    private static func key(for request: URLRequest) -> String {
        request.url.map(key(for:)) ?? ""
    }

    private static func stub(for request: URLRequest) -> Stub? {
        lock.lock(); defer { lock.unlock() }
        return stubsByKey[key(for: request)]
    }

    private static func record(_ request: URLRequest) {
        let captured = CapturedRequest(
            url: request.url,
            headers: request.allHTTPHeaderFields ?? [:],
            body: drainBody(of: request)
        )
        lock.lock(); defer { lock.unlock() }
        capturedByKey[key(for: request)] = captured
    }

    /// Reads the request body. `URLSession` streams `httpBody`, so it must be drained from
    /// `httpBodyStream`; `httpBody` itself is `nil` by the time the protocol sees the request.
    private static func drainBody(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }

        var data = Data()
        stream.open()
        defer { stream.close() }
        let bufferSize = 1_024
        while stream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data.isEmpty ? nil : data
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.record(self.request)

        guard let stub = Self.stub(for: self.request) else {
            // No canned response registered for this host + path. Fail loudly so a missing
            // or colliding stub registration surfaces immediately instead of passing vacuously.
            client?.urlProtocol(self, didFailWithError: StubError.noStubForRequest(self.request))
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let response = HTTPURLResponse(
            url: stub.responseURL ?? stub.url,
            statusCode: stub.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private enum StubError: LocalizedError, CustomStringConvertible {
        case noStubForRequest(URLRequest)

        /// Without this, `localizedDescription` reports "(StubError error 0)" and a missing
        /// stub surfaces as an unreadable failure.
        var errorDescription: String? { description }

        var description: String {
            switch self {
            case .noStubForRequest(let request):
                return "URLProtocolStub has no registered stub for \(request.url?.host ?? "")\(request.url?.path ?? "")"
            }
        }
    }
}
