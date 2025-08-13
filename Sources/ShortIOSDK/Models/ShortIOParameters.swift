import Foundation

public enum IntOrString: Encodable {
    case int(Int)
    case string(String)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

public struct ShortIOParameters: Encodable {
    public var domain: String?
    public let originalURL: String
    public var cloaking: Bool?
    public var password: String?
    public var redirectType: Int?
    public var expiresAt: IntOrString?
    public var expiredURL: String?
    public var title: String?
    public var tags: [String]?
    public var utmSource: String?
    public var utmMedium: String?
    public var utmCampaign: String?
    public var utmTerm: String?
    public var utmContent: String?
    public var ttl: IntOrString?
    public var path: String?
    public var androidURL: String?
    public var iphoneURL: String?
    public var createdAt: IntOrString?
    public var clicksLimit: Int?
    public var passwordContact: Bool?
    public var skipQS: Bool
    public var archived: Bool
    public var splitURL: String?
    public var splitPercent: Int?
    public var integrationAdroll: String?
    public var integrationFB: String?
    public var integrationGA: String?
    public var integrationGTM: String?
    public var folderId: String?

    public init(
        domain: String? = nil,
        originalURL: String,
        cloaking: Bool? = nil,
        password: String? = nil,
        redirectType: Int? = nil,
        expiresAt: IntOrString? = nil,
        expiredURL: String? = nil,
        title: String? = nil,
        tags: [String]? = nil,
        utmSource: String? = nil,
        utmMedium: String? = nil,
        utmCampaign: String? = nil,
        utmTerm: String? = nil,
        utmContent: String? = nil,
        ttl: IntOrString? = nil,
        path: String? = nil,
        androidURL: String? = nil,
        iphoneURL: String? = nil,
        createdAt: IntOrString? = nil,
        clicksLimit: Int? = nil,
        passwordContact: Bool? = nil,
        skipQS: Bool = false,
        archived: Bool = false,
        splitURL: String? = nil,
        splitPercent: Int? = nil,
        integrationAdroll: String? = nil,
        integrationFB: String? = nil,
        integrationGA: String? = nil,
        integrationGTM: String? = nil,
        folderId: String? = nil
    ) {
        self.domain = domain
        self.originalURL = originalURL
        self.cloaking = cloaking
        self.password = password
        self.redirectType = redirectType
        self.expiresAt = expiresAt
        self.expiredURL = expiredURL
        self.title = title
        self.tags = tags
        self.utmSource = utmSource
        self.utmMedium = utmMedium
        self.utmCampaign = utmCampaign
        self.utmTerm = utmTerm
        self.utmContent = utmContent
        self.ttl = ttl
        self.path = path
        self.androidURL = androidURL
        self.iphoneURL = iphoneURL
        self.createdAt = createdAt
        self.clicksLimit = clicksLimit
        self.passwordContact = passwordContact
        self.skipQS = skipQS
        self.archived = archived
        self.splitURL = splitURL
        self.splitPercent = splitPercent
        self.integrationAdroll = integrationAdroll
        self.integrationFB = integrationFB
        self.integrationGA = integrationGA
        self.integrationGTM = integrationGTM
        self.folderId = folderId
    }
    
    private enum CodingKeys: String, CodingKey {
        case domain
        case originalURL
        case cloaking
        case password
        case redirectType
        case expiresAt
        case expiredURL
        case title
        case tags
        case utmSource = "utm_source"
        case utmMedium = "utm_medium"
        case utmCampaign = "utm_campaign"
        case utmTerm = "utm_term"
        case utmContent = "utm_content"
        case ttl
        case path
        case androidURL
        case iphoneURL
        case createdAt
        case clicksLimit
        case passwordContact
        case skipQS
        case archived
        case splitURL
        case splitPercent
        case integrationAdroll
        case integrationFB
        case integrationGA
        case integrationGTM
        case folderId
    }
}
