import Foundation
import CryptoKit

public class ShortIOSDK {
    @MainActor public static let shared = ShortIOSDK()

    // MARK: - Private Properties
    private var session: URLSession
    private var isInitialized = false
    private var apiKey: String = ""
    private var domain: String = ""

    // MARK: - Private Initializer
    private init() {
        self.session = .shared
    }

    // MARK: - Public Initialization
    /// Initialize the SDK with required API key and domain
    /// - Parameters:
    ///   - apiKey: Authentication key for Short.io API
    ///   - domain: Short.io domain to use for link creation
    ///   - session: Custom URLSession (defaults to shared session)
    /// - Note: This method should be called once before using any SDK functionality
    public func initialize(session: URLSession = .shared, apiKey: String, domain: String) {
        if !isInitialized {
            self.session = session
            self.apiKey = apiKey
            self.domain = domain
            self.isInitialized = true
        } else {
            print("SDK is already initialized.")
            return
        }
    }

    //    @available(*, deprecated, message: "Use instance apiKey instead")
    //    public struct DeprecatedAPIKey {
    //        let value: String
    //    }

    /// Creates a shortened link using Short.io API
    /// - Parameters:
    ///   - parameters: Configuration for the shortened link
    ///   - apiKey: Authentication key for Short.io API
    /// - Returns: Result containing either success response or error
    @available(macOS 12.0, iOS 15.0, *)

    public func createShortLink(
        parameters: ShortIOParameters,
        apiKey: String? = nil
    ) async throws -> ShortIOResult {

        // Safely construct API endpoint URL
        guard let url = URL(string: Constants.baseURL) else {
            throw ShortIOError.invalidURL
        }

        // Configure API request
        var request = URLRequest(
            url: url,
            timeoutInterval: Constants.requestTimeout
        )

        var finalParameters = parameters

        finalParameters.domain = parameters.domain != nil ? parameters.domain : self.domain

        var finalApiKey = apiKey != nil ? apiKey : self.apiKey

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(finalApiKey ?? "", forHTTPHeaderField: "Authorization")

        do {
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

                // Error responses
                let errorResponse = try JSONDecoder().decode(ShortIOErrorResponse.self, from: data)
                return .failure(errorResponse)
            }

            // Success range
            let successResponse = try JSONDecoder().decode(ShortIOResponse.self, from: data)
            return .success(successResponse)
        } catch {

            // Propagate encoding/decoding/network errors
            throw error
        }
    }

    @available(macOS 12.0, iOS 15.0, *)
    public func createSecure(originalURL: String) throws -> (securedOriginalURL: String, securedShortUrl: String) {

        do {
            // Generate a 128-bit AES-GCM key
            let key = SymmetricKey(size: .bits128)

            // Generate a 12-byte nonce (IV)
            let nonce = AES.GCM.Nonce()

            // Encrypt the original URL
            guard let urlData = originalURL.data(using: .utf8) else {
                throw ShortIOError.invalidURL
            }
            let sealedBox = try AES.GCM.seal(urlData, using: key, nonce: nonce)

            // Encode encrypted data and nonce to Base64
            let encryptedUrlBase64 = sealedBox.ciphertext.base64EncodedString()
            let nonceBase64 = sealedBox.nonce.withUnsafeBytes { Data($0).base64EncodedString() }

            // Construct secured URL
            let securedOriginalURL = "shortsecure://\(encryptedUrlBase64)?\(nonceBase64)"

            // Export key as Base64
            let keyData = key.withUnsafeBytes { Data($0) }
            let keyBase64 = keyData.base64EncodedString()
            let securedShortUrl = "#\(keyBase64)"

            return (securedOriginalURL, securedShortUrl)
        } catch {
            throw error
        }
    }

    @available(macOS 12.0, iOS 15.0, *)
    public func trackConversion(clid: String, domain: String? = nil, conversionId: String? = nil) async throws -> Bool {

        // Create the base URL by removing trailing slash if exists
        let finalDomain = (domain ?? self.domain)?.trimmingCharacters(in: ["/"]) ?? ""

        let finalClid = clid ?? ""

        // Construct the conversion path with clid parameter
        var conversionURLString = "https://\(finalDomain)/.shortio/conversion?clid=\(finalClid)"

        if let conversionId = conversionId {
            conversionURLString += "&c=\(conversionId)"
        }

        guard let url = URL(string: conversionURLString) else {
            print("Invalid URL constructed: \(conversionURLString)")
            return false
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                return false
            }

            // Return true only for successful status codes (typically 200-299)
            return (200...299).contains(httpResponse.statusCode)

        } catch {
            throw error
        }
    }

    @MainActor
    public func handleOpen(_ url: URL, completion: @escaping URLHandlerCompletion) {
        // Validation
        do {
            var handler = URLHandler.shared
            let components = try handler.createURLComponents(from: url)

            handler.handleClick(urlComponents: components, completion: completion)
        } catch {
            completion(.failure(error as! URLHandlerError))
        }
    }
}

// MARK: - Result Type
/// Result type for Short.io API operations
public enum ShortIOResult {
    case success(ShortIOResponse)
    case failure(ShortIOErrorResponse)
}

// MARK: - Error Handling
/// Custom errors for Short.io operations
public enum ShortIOError: Error {
    case invalidURL
    case invalidResponse
}

/// Extension to provide localized error descriptions
extension ShortIOError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Received malformed server response"
        }
    }
}
