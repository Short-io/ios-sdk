import Testing
import Foundation
@testable import ShortIOSDK

/// Regression guard for the `domain` → `_domain` storage change.
struct ShortIOParametersEncodingTests {

    @Test func domainEncodesUnderDomainKey() throws {
        let parameters = ShortIOParameters(domain: "demo.short.io", originalURL: "https://long.example/page")

        let data = try JSONEncoder().encode(parameters)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // The internal `_domain` storage must stay invisible on the wire.
        #expect(json["domain"] as? String == "demo.short.io")
        #expect(json["_domain"] == nil)
    }
}
