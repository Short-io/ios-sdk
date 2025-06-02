import Foundation

public class ShortIOSDK {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }

    @available(macOS 12.0, iOS 15.0, *)
    public func createShortLink(
        parameters: ShortIOParameters,
        apiKey: String
    ) async throws -> ShortIOResponse {
        guard let url = URL(string: Constants.baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(parameters)
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShortIOError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ShortIOError.httpError(statusCode: httpResponse.statusCode)
            }
            
            return try JSONDecoder().decode(ShortIOResponse.self, from: data)
        } catch DecodingError.dataCorrupted(_) {
            throw ShortIOError.invalidResponse
        } catch {
            throw ShortIOError.networkError(error)
        }
    }
}

public enum ShortIOError: Error {
    case networkError(Error)
    case invalidResponse
    case invalidParameters
    case httpError(statusCode: Int)
}

extension ShortIOError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .invalidParameters:
            return "Invalid parameters provided"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        }
    }
}
