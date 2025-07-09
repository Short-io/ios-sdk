import Foundation
import CryptoKit

public class ShortIOSDK {
    private let session: URLSession

    /// Initialize with a custom URLSession (defaults to shared session)
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Creates a shortened link using Short.io API
    /// - Parameters:
    ///   - parameters: Configuration for the shortened link
    ///   - apiKey: Authentication key for Short.io API
    /// - Returns: Result containing either success response or error
    @available(macOS 12.0, iOS 15.0, *)
    public func createShortLink(
        parameters: ShortIOParameters,
        apiKey: String
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
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")

        do {
            // Encode request parameters
            request.httpBody = try JSONEncoder().encode(parameters)

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
    public func trackConversion(originalURL: String, clid: String, conversionId: String) async throws -> Bool {

        // Create the base URL by removing trailing slash if exists
        let baseURL = originalURL.hasSuffix("/") ? String(originalURL.dropLast()) : originalURL

        // Construct the conversion path with clid parameter
        let conversionURLString = "\(baseURL)/.shortio/conversion?c=\(conversionId)&clid=\(clid)"

        guard let url = URL(string: conversionURLString) else {
            print("Invalid URL constructed: \(conversionURLString)")
            return false
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

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

    func handleClick(urlComponents: URLComponents, completion: @escaping (URLComponents?, String?) -> Void) {
        var components = urlComponents

        // Add utm_medium=ios parameter
        var queryItems = components.queryItems ?? []
        if !queryItems.contains(where: { $0.name == "utm_medium" }) {
            queryItems.append(URLQueryItem(name: "utm_medium", value: "ios"))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            completion(nil, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                // Return original URL without utm_medium in case of error
                completion(urlComponents, "Network error: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(urlComponents, "Invalid server response")
                return
            }

            var resultComponents = urlComponents

            // Check for clid in headers
            print("Short SDK click call completed successfully")
            if let clid = httpResponse.allHeaderFields["Clid"] as? String {
                // Remove utm_medium and add clid parameter
                var newQueryItems = resultComponents.queryItems ?? []
                newQueryItems.removeAll(where: { $0.name == "utm_medium" })
                newQueryItems.append(URLQueryItem(name: "clid", value: clid))
                resultComponents.queryItems = newQueryItems
            } else {
                // Keep the original URL (without utm_medium) if no clid found
                resultComponents = urlComponents
            }

            switch httpResponse.statusCode {
            case 200:
                completion(resultComponents, nil) // Success
            case 404:
                completion(urlComponents, "Link is not valid") // Specific error for 404
            default:
                completion(urlComponents, "Unexpected status code: \(httpResponse.statusCode)")
            }
        }.resume()
    }

    public func handleOpen(_ url: URL, completion: @escaping (URLComponents?, String?) -> Void) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme,
              ["http", "https"].contains(scheme) else {
            completion(nil, "Invalid URL scheme")
            return
        }

        handleClick(urlComponents: components) { modifiedComponents, error in
            if let error = error {
                // Return original URL in case of error
                completion(components, error)
                return
            }

            guard let resultComponents = modifiedComponents else {
                completion(components, "Unknown error occurred")
                return
            }

            // Process path if needed
            if let firstPathComponent = resultComponents.path.split(separator: "/").first {
                var finalComponents = resultComponents
                finalComponents.path = "\(firstPathComponent)"
                completion(finalComponents, nil)
            } else {
                completion(resultComponents, nil)
            }
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
