import Foundation

// MARK: - Error Types
public enum URLHandlerError: LocalizedError {
    case notInitialized
    case invalidURL
    case invalidURLScheme
    case networkError(Error)
    case invalidServerResponse
    case invalidResponseURL
    case linkNotValid
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

class URLHandler {
    @MainActor static let shared = URLHandler()
    private let session: URLSession
    private var isInitialized: Bool

    init(session: URLSession = .shared) {
        self.session = session
        self.isInitialized = false // Assuming this is set elsewhere
    }

    func createURLComponents(from url: URL) throws -> URLComponents {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
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
        request.timeoutInterval = 30.0 // Add timeout for better UX
        return request
    }

    private func extractClid(from url: String) throws -> String? {
        // Convert the URL string to a URL object
        guard let url = URL(string: url) else {
            throw URLHandlerError.invalidURL
        }

        // Parse the URL into components
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLHandlerError.invalidURL
        }

        // Extract the clid query parameter
        return components.queryItems?.first(where: { $0.name == "clid" })?.value
    }

    private func processHTTPResponse(_ response: URLResponse?) throws -> URLComponents {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLHandlerError.invalidServerResponse
        }

        guard let responseURL = httpResponse.url else {
            throw URLHandlerError.invalidResponseURL
        }

        guard var responseComponents = URLComponents(url: responseURL, resolvingAgainstBaseURL: false) else {
            throw URLHandlerError.invalidResponseURL
        }

        // Process based on status code
        switch httpResponse.statusCode {
        case 200:
            responseComponents.removeUTMMedium()
            print("Short SDK click call completed successfully")
            return responseComponents
        case 404:
            throw URLHandlerError.linkNotValid
        default:
            throw URLHandlerError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }

    // MARK: - Public Methods
    func handleClick(urlComponents: URLComponents, completion: @escaping URLHandlerCompletion) {

        // Prepare components with UTM parameter
        var components = urlComponents
        components.addUTMMediumIOS()

        // Create request
        let request: URLRequest
        do {
            request = try createURLRequest(from: components)
        } catch {
            completion(.failure(error as! URLHandlerError))
            return
        }

        // Execute network request
        session.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }

                do {
                    let processedComponents = try self?.processHTTPResponse(response) ?? {
                        throw URLHandlerError.unknownError
                    }()
                    completion(.success(processedComponents))
                } catch {
                    completion(.failure(error as! URLHandlerError))
                }
            }
        }.resume()
    }
}
