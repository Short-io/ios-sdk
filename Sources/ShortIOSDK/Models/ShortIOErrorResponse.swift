public struct ShortIOErrorResponse: Decodable {
    public let message: String
    public let code: String?
    public let statusCode: Int
    public let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case message
        case code
        case statusCode
        case success
    }
}
