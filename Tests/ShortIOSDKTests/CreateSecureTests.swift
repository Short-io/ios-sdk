import Testing
import Foundation
@testable import ShortIOSDK

struct CreateSecureTests {

    @Test func securedURLUsesShortsecureSchemeAndBase64Parts() throws {
        let sdk = ShortIOSDK()

        let result = try sdk.createSecure(originalURL: "https://example.com/page")

        #expect(result.securedOriginalURL.hasPrefix("shortsecure://"))
        #expect(result.securedShortUrl.hasPrefix("#"))

        // Body is "<ciphertext>?<nonce>", both Base64.
        let body = result.securedOriginalURL.replacingOccurrences(of: "shortsecure://", with: "")
        let parts = body.split(separator: "?")
        #expect(parts.count == 2)
        #expect(Data(base64Encoded: String(parts[0])) != nil)
        #expect(Data(base64Encoded: String(parts[1])) != nil)

        // Key is a 128-bit AES key, Base64 of 16 bytes.
        let keyBase64 = String(result.securedShortUrl.dropFirst())
        #expect(Data(base64Encoded: keyBase64)?.count == 16)
    }
}
