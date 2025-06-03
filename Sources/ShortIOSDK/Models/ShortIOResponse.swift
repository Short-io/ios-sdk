import Foundation

public struct ShortIOResponse: Decodable {
    public let originalURL: String
    public let path: String
    public let idString: String
    public let id: String
    public let shortURL: String
    public let secureShortURL: String
    public let cloaking: Bool
    public let tags: [String]
    public let createdAt: String // Changed to String to match ISO 8601 format
    public let skipQS: Bool
    public let archived: Bool
    public let domainId: Int
    public let ownerId: Int
    public let hasPassword: Bool
    public let source: String
    public let success: Bool
    public let duplicate: Bool
    public let password: String?
    public let expiresAt: Int?
    public let expiredURL: String?
    public let title: String?
    public let utmSource: String?
    public let utmMedium: String?
    public let utmCampaign: String?
    public let utmTerm: String?
    public let utmContent: String?
    public let ttl: String?
    public let androidURL: String?
    public let iphoneURL: String?
    public let clicksLimit: Int?
    public let passwordContact: Bool?
    public let splitURL: String?
    public let splitPercent: Int?
    public let integrationAdroll: String?
    public let integrationFB: String?
    public let integrationGA: String?
    public let integrationGTM: String?
    public let folderId: String?
    public let redirectType: String?
    public let user: User?


    private enum CodingKeys: String, CodingKey {
        case originalURL
        case path
        case idString
        case id
        case shortURL
        case secureShortURL
        case cloaking
        case tags
        case createdAt
        case skipQS
        case archived
        case domainId = "DomainId"
        case ownerId = "OwnerId"
        case hasPassword
        case source
        case success
        case duplicate
        case password
        case expiresAt
        case expiredURL
        case title
        case utmSource = "utm_source"
        case utmMedium = "utm_medium"
        case utmCampaign = "utm_campaign"
        case utmTerm = "utm_term"
        case utmContent = "utm_content"
        case ttl
        case androidURL
        case iphoneURL
        case clicksLimit
        case passwordContact
        case splitURL
        case splitPercent
        case integrationAdroll
        case integrationFB
        case integrationGA
        case integrationGTM
        case folderId = "FolderId"
        case redirectType
        case user = "User"
    }
}
