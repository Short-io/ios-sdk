import Foundation

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

extension ShortIOError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .invalidResponse:
            return "Received malformed server response"
        }
    }
}
