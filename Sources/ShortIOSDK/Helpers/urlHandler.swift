import Foundation

// MARK: - Error Types
public enum URLHandlerError: LocalizedError, Sendable {
    @available(*, deprecated, message: "Never thrown. Superseded by ShortIOError.notInitialized. Removed in 2.0.0.")
    case notInitialized
    case invalidURL
    case invalidURLScheme
    case networkError(any Error & Sendable)
    case invalidServerResponse
    case invalidResponseURL
    /// The short link itself was not found — the shortener returned 404 without redirecting.
    case linkNotValid
    /// The short link resolved, but its destination answered with a failure status.
    /// The link is fine; the page it points at is not.
    case destinationUnavailable(statusCode: Int, destination: URL)
    case unexpectedStatusCode(Int)
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "SDK not initialized. Call initialize() first."
        case .invalidURL:
            return "Invalid URL"
        case .invalidURLScheme:
            return "Invalid URL scheme"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidServerResponse:
            return "Invalid server response"
        case .invalidResponseURL:
            return "Invalid server response URL"
        case .linkNotValid:
            return "Link is not valid"
        case .destinationUnavailable(let code, let destination):
            return "Short link resolved to \(destination.absoluteString), which returned status \(code)"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}

// MARK: - Result Type
public typealias URLHandlerResult = Result<URLComponents, URLHandlerError>
public typealias URLHandlerCompletion = (URLHandlerResult) -> Void

extension URLComponents {
    /// Adds or updates utm_medium parameter with "ios" value
    mutating func addUTMMediumIOS() {
        var queryItems = self.queryItems ?? []

        // Remove existing utm_medium if present
        queryItems.removeAll { $0.name == "utm_medium" }

        // Add new utm_medium parameter
        queryItems.append(URLQueryItem(name: "utm_medium", value: "ios"))
        self.queryItems = queryItems
    }

    /// Removes utm_medium parameter
    mutating func removeUTMMedium() {
        queryItems?.removeAll { $0.name == "utm_medium" }

        // Set to nil if no query items remain
        if queryItems?.isEmpty == true {
            queryItems = nil
        }
    }
}

final class URLHandler: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func createURLComponents(from url: URL) throws -> URLComponents {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            throw URLHandlerError.invalidURLScheme
        }
        return components
    }

    private func createURLRequest(from components: URLComponents) throws -> URLRequest {
        guard let url = components.url else {
            throw URLHandlerError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = Constants.requestTimeout
        return request
    }

    /// - Parameter requestedURL: The short link that was requested. `URLSession` follows redirects,
    ///   so a failure status may belong to the destination rather than to the short link itself;
    ///   comparing the two is what tells them apart.
    private func processHTTPResponse(_ response: URLResponse?, requestedURL: URL?) throws -> URLComponents {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLHandlerError.invalidServerResponse
        }

        guard let responseURL = httpResponse.url else {
            throw URLHandlerError.invalidResponseURL
        }

        guard var responseComponents = URLComponents(url: responseURL, resolvingAgainstBaseURL: false) else {
            throw URLHandlerError.invalidResponseURL
        }

        // A redirect means the shortener resolved the link and we are now looking at the
        // destination's response, so its status must not be blamed on the short link.
        let didRedirect = requestedURL.map { responseURL.absoluteString != $0.absoluteString } ?? false

        // Process based on status code
        switch httpResponse.statusCode {
        case 200:
            responseComponents.removeUTMMedium()
            return responseComponents
        case let code where didRedirect:
            throw URLHandlerError.destinationUnavailable(statusCode: code, destination: responseURL)
        case 404:
            throw URLHandlerError.linkNotValid
        default:
            throw URLHandlerError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }

    // MARK: - Public Methods
    /// Performs the click request and returns the processed components plus any `clid`.
    func handleClick(
        urlComponents: URLComponents
    ) async throws -> (components: URLComponents, clid: String?) {

        // Prepare components with UTM parameter
        var components = urlComponents
        components.addUTMMediumIOS()

        let request = try createURLRequest(from: components)

        let response: URLResponse
        do {
            (_, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            // URLSession reports cancellation as URLError(.cancelled), which is not a network failure.
            throw CancellationError()
        } catch {
            throw URLHandlerError.networkError(error as NSError)
        }

        let processedComponents = try processHTTPResponse(response, requestedURL: request.url)
        let clid = processedComponents.queryItems?.first(where: { $0.name == "clid" })?.value
        return (processedComponents, clid)
    }
}
