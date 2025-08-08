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

    @available(iOS 13.0.0, *)
    public func handleOpen(_ url: URL,completion: @escaping (_ components: URLComponents?,_ redirectedURL: String?, _ error: String?) -> Void) async {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme,
              ["http", "https"].contains(scheme) else {
            completion(nil, nil, "Invalid URL scheme")
            return
        }

        let destinationURL = await handleConversionTracking(url: url)

        handleClick(urlComponents: components) { modifiedComponents, error in
            if let error = error {
                completion(components, destinationURL, error)
                return
            }

            guard let resultComponents = modifiedComponents else {
                completion(components, destinationURL, "Unknown error occurred")
                return
            }

            // Process path if needed
            if let firstPathComponent = resultComponents.path.split(separator: "/").first {
                var finalComponents = resultComponents
                finalComponents.path = "\(firstPathComponent)"
                completion(finalComponents, destinationURL, nil)
            } else {
                completion(resultComponents, destinationURL, nil)
            }
        }
    }


    @available(iOS 13.0.0, *)
    public func handleConversionTracking(url: URL) async -> String? {
        let originalURLString = url.absoluteString
        do {
            if let redirectedURLString = try await ConversionTrackingMethods.fetchHeaderValue(from: originalURLString),
               let redirectedURL = URL(string: redirectedURLString),
               let components = URLComponents(url: redirectedURL, resolvingAgainstBaseURL: false),
               let clid = components.queryItems?.first(where: { $0.name == "clid" })?.value {

                print("clid =", clid)
                print("Redirected URL: \(redirectedURLString)")

                ConversionTrackingMethods.trackConversion(
                    originalURL: originalURLString,
                    clid: clid
                )

                return redirectedURLString
            } else {
                print("Failed to extract clid or redirect URL")
                return nil
            }
        } catch {
            print("Error: \(error)")
            return nil
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

public enum ConversionTrackingMethods {
    @available(iOS 13.0.0, *)
    static func fetchHeaderValue(from urlString: String) async throws -> String? {
        guard let url = URL(string: urlString) else {
            print("Invalid input URL: \(urlString)")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Failed to cast response to HTTPURLResponse")
                return nil
            }
            
            print("Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("  \(key): \(value)")
            }

            guard let redirectedURL = httpResponse.url else {
                print("No redirection occurred. Returning original URL.")
                return url.absoluteString
            }

            return redirectedURL.absoluteString
        } catch {
            print("Network error: \(error.localizedDescription)")
            return nil
        }
    }

    
    @available(iOS 13.0.0, *)
    static func trackConversion(originalURL: String, clid: String?) {
        Task.detached {
            let originalURLString =
                originalURL.hasSuffix("/") ? String(originalURL.dropLast()) : originalURL
            guard let baseURL = URL(string: originalURLString),
                let host = baseURL.host,
                let scheme = baseURL.scheme
            else {
                print("Invalid base URL: \(originalURL)")
                return
            }

            var components = URLComponents()
            components.scheme = scheme
            components.host = host
            components.path = "/.shortio/conversion"

            var queryItems = [URLQueryItem]()
            if let clid = clid {
                queryItems.append(URLQueryItem(name: "clid", value: clid))
            }
            components.queryItems = queryItems

            guard let url = components.url else {
                print("Failed to construct conversion URL")
                return
            }

            print("Sending conversion request to: \(url)")

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response type")
                    return
                }

                print("Response status code: \(httpResponse.statusCode)")
                let success = (200...299).contains(httpResponse.statusCode)
                print("Conversion tracking success: \(success)")
            } catch {
                print("Request failed: \(error.localizedDescription)")
            }
        }
    }

}
