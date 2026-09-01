import Foundation
import CryptoKit

public final class ShortIOSDK: Sendable {
    public static let shared = ShortIOSDK()

    // MARK: - Private Properties
    private let state = LockedState(Config())

    // MARK: - Initializer
    init() {}

    // MARK: - Public Initialization
    /// Initialize the SDK with required API key and domain
    /// - Parameters:
    ///   - apiKey: Authentication key for Short.io API
    ///   - domain: Short.io domain to use for link creation
    ///   - session: Custom URLSession (defaults to shared session)
    /// - Note: This method should be called once before using any SDK functionality
    public func initialize(session: URLSession = .shared, apiKey: String, domain: String) {
        state.withLock { config in
            // Subsequent calls are ignored; the first configuration wins.
            guard !config.isInitialized else { return }
            config.session = session
            config.apiKey = apiKey
            config.domain = domain
            config.isInitialized = true
        }

    }

    // MARK: - Internal Test Accessors
    var clidForTesting: String { state.withLock { $0.clid } }
    var apiKeyForTesting: String { state.withLock { $0.apiKey } }
    var domainForTesting: String { state.withLock { $0.domain } }
    func setClidForTesting(_ clid: String) { state.withLock { $0.clid = clid } }

    /// Throws `.notInitialized` unless `initialize(apiKey:domain:)` has been called.
    private func ensureInitialized() throws {
        let isInitialized = state.withLock { $0.isInitialized }
        guard isInitialized else { throw ShortIOError.notInitialized }
    }

    private func performCreateShortLink(parameters: ShortIOParameters, apiKey: String?) async throws -> ShortIOResult {
        let (session, configuredDomain) = state.withLock { ($0.session, $0.domain) }

        guard let url = URL(string: Constants.baseURL) else {
            throw ShortIOError.invalidURL
        }

        // Configure API request
        var request = URLRequest(
            url: url,
            timeoutInterval: Constants.requestTimeout
        )

        var finalParameters = parameters

        // The API requires `domain` and never derives it from the key. Fall back to the
        // configured one; leave validating it to the API.
        finalParameters._domain = parameters._domain ?? configuredDomain

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey ?? "", forHTTPHeaderField: "Authorization")

        // Encode request parameters
        request.httpBody = try JSONEncoder().encode(finalParameters)

        // Execute network request
        let (data, response) = try await session.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShortIOError.invalidResponse
        }

        // Handle HTTP status codes
        guard (200...299).contains(httpResponse.statusCode) else {

            // Decode leniently: a non-JSON body must not escalate into a thrown error.
            if let errorResponse = try? JSONDecoder().decode(ShortIOErrorResponse.self, from: data) {
                return .failure(errorResponse)
            }
            return .failure(ShortIOErrorResponse(
                message: "Request failed with status code \(httpResponse.statusCode).",
                code: nil,
                statusCode: httpResponse.statusCode,
                success: false
            ))
        }

        // Success range
        let successResponse = try JSONDecoder().decode(ShortIOResponse.self, from: data)
        return .success(successResponse)
    }

    /// Creates a shortened link using Short.io API
    /// - Parameters:
    ///   - parameters: Configuration for the shortened link
    ///   - apiKey: Authentication key for Short.io API
    /// - Returns: Result containing either success response or error
    @available(*, deprecated, renamed: "createShortLink(parameters:)",
               message: "Parameter 'apiKey' is deprecated. Call initialize(apiKey:domain:) first, then use createShortLink(parameters:). This overload will be removed in future releases.")
    public func createShortLink(
        parameters: ShortIOParameters,
        apiKey: String? = nil
    ) async throws -> ShortIOResult {

        // Skips `ensureInitialized()`: this overload takes `apiKey` directly.
        return try await performCreateShortLink(parameters: parameters, apiKey: apiKey)

    }

    public func createShortLink(
        parameters: ShortIOParameters
    ) async throws -> ShortIOResult {

        try ensureInitialized()

        // Safely construct API endpoint URL
        return try await performCreateShortLink(
            parameters: parameters,
            apiKey: state.withLock { $0.apiKey }
        )
    }

    public func createSecure(originalURL: String) throws -> (securedOriginalURL: String, securedShortUrl: String) {

        // Generate a 128-bit AES-GCM key
        let key = SymmetricKey(size: .bits128)

        // Generate a 12-byte nonce (IV)
        let nonce = AES.GCM.Nonce()

        // Encrypt the original URL
        guard let urlData = originalURL.data(using: .utf8) else {
            throw ShortIOError.invalidURL
        }
        let sealedBox = try AES.GCM.seal(urlData, using: key, nonce: nonce)

        // The decrypter is WebCrypto AES-GCM, which expects the tag appended to the ciphertext.
        let encryptedUrlBase64 = (sealedBox.ciphertext + sealedBox.tag).base64EncodedString()
        let nonceBase64 = sealedBox.nonce.withUnsafeBytes { Data($0).base64EncodedString() }

        // Construct secured URL
        let securedOriginalURL = "shortsecure://\(encryptedUrlBase64)?\(nonceBase64)"

        // Export key as Base64
        let keyData = key.withUnsafeBytes { Data($0) }
        let keyBase64 = keyData.base64EncodedString()
        let securedShortUrl = "#\(keyBase64)"

        return (securedOriginalURL, securedShortUrl)
    }

    /// Records a conversion for a link previously resolved by `handleOpen(_:)`.
    ///
    /// The `clid` captured during `handleOpen(_:)` and the domain supplied to
    /// `initialize(apiKey:domain:)` are used automatically.
    /// - Parameter conversionId: Optional identifier for the conversion event.
    /// - Returns: `true` if the conversion request succeeded.
    public func trackConversion(conversionId: String? = nil) async throws -> Bool {
        try ensureInitialized()
        return try await performTrackConversion(clid: nil, domain: nil, conversionId: conversionId)
    }

    @available(*, deprecated, renamed: "trackConversion(conversionId:)",
               message: "'clid' is captured by handleOpen(_:) and 'domain' by initialize(apiKey:domain:), so neither needs to be passed. This overload will be removed in future releases.")
    public func trackConversion(clid: String?, domain: String? = nil, conversionId: String? = nil) async throws -> Bool {
        // Skips `ensureInitialized()`: this overload takes `clid`/`domain` directly.
        return try await performTrackConversion(clid: clid, domain: domain, conversionId: conversionId)
    }

    private func performTrackConversion(clid: String?, domain: String?, conversionId: String?) async throws -> Bool {

        let (session, configuredDomain, storedClid) = state.withLock {
            ($0.session, $0.domain, $0.clid)
        }
        let domainToUse = domain ?? configuredDomain
        let finalDomain = domainToUse.trimmingCharacters(in: ["/"])
        let finalClid = clid ?? storedClid

        // Without a clid the endpoint can only fail, and handleOpen(_:) is what records one.
        guard !finalClid.trimmingCharacters(in: .whitespaces).isEmpty,
              !finalDomain.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }

        // Query items percent-encode reserved characters, which interpolation would not.
        var components = URLComponents()
        components.scheme = "https"
        components.host = finalDomain
        components.path = "/.shortio/conversion"
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "clid", value: finalClid)]
        if let conversionId {
            queryItems.append(URLQueryItem(name: "c", value: conversionId))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw ShortIOError.invalidURL
        }

        let (_, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShortIOError.invalidResponse
        }

        // Return true only for successful status codes (typically 200-299)
        return (200...299).contains(httpResponse.statusCode)
    }

    /// Resolves an incoming Short.io link, recording its `clid` for conversion tracking.
    /// - Parameter url: The universal link the app was opened with.
    /// - Returns: The processed URL components of the destination.
    /// - Throws: `URLHandlerError` if the scheme is unsupported or the request fails.
    public func handleOpen(_ url: URL) async throws -> URLComponents {
        let session = state.withLock { $0.session }
        let handler = URLHandler(session: session)

        let components = try handler.createURLComponents(from: url)
        let (processedComponents, clid) = try await handler.handleClick(urlComponents: components)

        if let clid {
            state.withLock { $0.clid = clid }
        }

        return processedComponents
    }

    @available(*, deprecated, renamed: "handleOpen(_:)",
               message: "Use the async handleOpen(_:) instead. This overload will be removed in future releases.")
    @MainActor
    public func handleOpen(_ url: URL, completion: @escaping URLHandlerCompletion) {
        Task { @MainActor in
            do {
                let components = try await handleOpen(url)
                completion(.success(components))
            } catch let error as URLHandlerError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError))
            }
        }
    }
}

// MARK: - Result Type
/// Result type for Short.io API operations
public enum ShortIOResult: Sendable {
    case success(ShortIOResponse)
    case failure(ShortIOErrorResponse)
}

// MARK: - Error Handling
/// Custom errors for Short.io operations
public enum ShortIOError: Error, Sendable {
    case notInitialized
    case invalidURL
    case invalidResponse
}

/// Extension to provide localized error descriptions
extension ShortIOError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "SDK not initialized. Call initialize(apiKey:domain:) first."
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Received malformed server response"
        }
    }
}
