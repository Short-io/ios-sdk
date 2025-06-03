import Foundation

public struct User: Decodable {
    public let id: Int
    public let name: String
    public let email: String
    public let photoURL: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case photoURL
    }
}
