import Testing
import Foundation
import CryptoKit
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

    @Test func ciphertextCarriesTheGCMTag() throws {
        let sdk = ShortIOSDK()
        let originalURL = "https://example.com/page"

        let result = try sdk.createSecure(originalURL: originalURL)

        let body = result.securedOriginalURL.replacingOccurrences(of: "shortsecure://", with: "")
        let parts = body.split(separator: "?")
        let ciphertext = Data(base64Encoded: String(parts[0]))

        #expect(ciphertext?.count == originalURL.utf8.count + 16)
    }

    @Test func nonceEncodesWithoutBase64Padding() throws {
        let sdk = ShortIOSDK()

        let result = try sdk.createSecure(originalURL: "https://example.com/page")

        let body = result.securedOriginalURL.replacingOccurrences(of: "shortsecure://", with: "")
        let nonce = String(body.split(separator: "?")[1])

        #expect(nonce.count == 16)
        #expect(!nonce.contains("="))
    }

    @Test func roundTripsThroughStandardAESGCM() throws {
        let sdk = ShortIOSDK()
        let originalURL = "https://example.com/page?token=abc"

        let result = try sdk.createSecure(originalURL: originalURL)

        let body = result.securedOriginalURL.replacingOccurrences(of: "shortsecure://", with: "")
        let parts = body.split(separator: "?")
        let payload = Data(base64Encoded: String(parts[0]))!
        let nonce = Data(base64Encoded: String(parts[1]))!
        let key = Data(base64Encoded: String(result.securedShortUrl.dropFirst()))!

        let decrypted = try decryptGCM(payload: payload, nonce: nonce, key: key)

        #expect(String(data: decrypted, encoding: .utf8) == originalURL)
    }
}

private func decryptGCM(payload: Data, nonce: Data, key: Data) throws -> Data {
    let box = try AES.GCM.SealedBox(
        nonce: try AES.GCM.Nonce(data: nonce),
        ciphertext: payload.prefix(payload.count - 16),
        tag: payload.suffix(16)
    )
    return try AES.GCM.open(box, using: SymmetricKey(data: key))
}
