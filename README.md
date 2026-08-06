
# ShortLink SDK for iOS (Deep Linking Integration using Short.io)

[![CI](https://github.com/Short-io/ios-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/Short-io/ios-sdk/actions/workflows/ci.yml)

This SDK allows you to create short links using the [Short.io](https://short.io/) API based on a public API key and custom parameters. It also supports iOS deep linking integration using Universal Links.

## ✨ Features

- Generate short links via Short.io API
- Customize short links using parameters
- Integrate iOS Universal Links (Deep Linking)
- Singleton-based API access for simplified usage
- AES-encrypted secure short link support
- Simple and clean API for developers


## 📦 Installation

You can integrate the SDK into your Xcode project using **Swift Package Manager (SPM)** or **Manual Installation**.

### 🚀 Swift Package Manager (Recommended)

To install the SDK via Swift Package Manager:

1. Open your Xcode project.
2. Go to **File > Add Packages Dependencies**
3. In the search bar, paste the SDK’s GitHub repository URL:
```arduino
https://github.com/Short-io/ios-sdk/
```
4. Choose the latest version or a specific branch.
5. Click Add Package.
5. Import the SDK where needed:
```swift
import ShortIOSDK
```

### 🔧 Manual Installation

If you prefer to install the SDK manually:

1. Clone or download the SDK repository.
2. Open your Xcode project.
3. Go to **File > Add Packages Dependencies**
4. Click the **Add Local Package** button.
5. Select the downloaded SDK folder.
6. Click **Add Package**.

## 🔑 Getting Started


### Get Public API Key from Short.io

1. Visit [Short.io](https://short.io/) and **sign up** or **log in** to your account.
3. In the dashboard, navigate to **Integrations & API**.
4. Click **CREATE API KEY** button.
5. Enable the **Public Key** toggle.
7. Click **CREATE** to generate your API key.

## 🔗 SDK Usage

### Initialize the SDK

Before using any functionality, you must initialize the SDK using your API key and domain in `AppDelegate` as part of application(launchOptions) for a UIKit app, or the @main initialization logic for a SwiftUI app.



```swift
...
import ShortIOSDK
...

class AppDelegate: UIResponder, UIApplicationDelegate {
  ...
  func application(...) {
    ...
    let sdk = ShortIOSDK.shared

    sdk.initialize(apiKey: "your_apiKey_here", domain: "your_domain_here")
    ...
  }
  ...
}
```

**Note:** Both `apiKey` and `domain` are the required parameters.

### 🔹 Create a Short Link
```swift
import ShortIOSDK

let sdk = ShortIOSDK.shared

// The domain comes from initialize(apiKey:domain:) — no need to repeat it here.
let parameters = ShortIOParameters(
    originalURL: "https://example.com/your/long/url" // the URL you want shortened
)
```
**Note**: `originalURL` is the only required parameter — and it is the **destination** URL you want to shorten, not your Short.io domain. You can also pass optional parameters such as `path`, `title`, `utmSource`, etc.

- The `domain` parameter is deprecated and will be removed in 2.0.0. A domain is still **required** by the API — supply it once via `initialize(apiKey:domain:)` and every request will use it. Setting `domain` here overrides that for a single call.

``` swift
let apiKey = "your_public_apiKey" // Replace with your Short.io Public API Key
        
Task {
    do {
        let result = try await sdk.createShortLink(
            parameters: parameters,
            apiKey: apiKey
        )
        switch result {
            case .success(let response):
                print("Short URL created: \(response.shortURL)")
            case .failure(let errorResponse):
                print("Error occurred: \(errorResponse.message), Code: \(errorResponse.code ?? "N/A")")
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
```
**⚠️ Note**: The `apiKey` parameter is deprecated. Call `initialize(apiKey:domain:)` first, then use `createShortLink(parameters:)`. This overload will be removed in 2.0.0.

## 📄 API Parameters

The `ShortIOParameters` struct is used to define the details of the short link you want to create. Below are the available parameters:


| Parameter           | Type         | Required  | Description                                                  |
| ------------------- | -----------  | --------  | ------------------------------------------------------------ |
| `domain`            | `String`     | ⚠️ (Deprecated)        | ⚠️ Deprecated — pass it to `initialize(apiKey:domain:)` instead, which supplies it for every request. Setting it here overrides that. Removed in 2.0.0. |
| `originalURL`       | `String`     | ✅        | The original URL to be shortened                             |
| `cloaking`          | `Bool`       | ❌        | If `true`, hides the destination URL from the user           |
| `password`          | `String`     | ❌        | Password to protect the short link                           |
| `redirectType`      | `Int`        | ❌        | Type of redirect (e.g., 301, 302)                            |
| `expiresAt`         | `IntOrString`| ❌        | Expiration timestamp in Unix format                          |
| `expiredURL`        | `String`     | ❌        | URL to redirect after expiration                             |
| `title`             | `String`     | ❌        | Custom title for the link                                    |
| `tags`              | `[String]`   | ❌        | Tags to categorize the link                                  |
| `utmSource`         | `String`     | ❌        | UTM source parameter                                         |
| `utmMedium`         | `String`     | ❌        | UTM medium parameter                                         |
| `utmCampaign`       | `String`     | ❌        | UTM campaign parameter                                       |
| `utmTerm`           | `String`     | ❌        | UTM term parameter                                           |
| `utmContent`        | `String`     | ❌        | UTM content parameter                                        |
| `ttl`               | `IntOrString`| ❌        | Time to live for the short link                              |
| `path`              | `String`     | ❌        | Custom path for the short link                               |
| `androidURL`        | `String`     | ❌        | Fallback URL for Android                                     |
| `iphoneURL`         | `String`     | ❌        | Fallback URL for iPhone                                      |
| `createdAt`         | `IntOrString`| ❌        | Custom creation timestamp                                    |
| `clicksLimit`       | `Int`        | ❌        | Maximum number of clicks allowed                             |
| `passwordContact`   | `Bool`       | ❌        | Whether contact details are required for password access     |
| `skipQS`            | `Bool`       | ❌        | If `true`, skips query string on redirect (default: `false`) |
| `archived`          | `Bool`       | ❌        | If `true`, archives the short link (default: `false`)        |
| `splitURL`          | `String`     | ❌        | URL for A/B testing                                          |
| `splitPercent`      | `Int`        | ❌        | Split percentage for A/B testing                             |
| `integrationAdroll` | `String`     | ❌        | AdRoll integration token                                     |
| `integrationFB`     | `String`     | ❌        | Facebook Pixel ID                                            |
| `integrationGA`     | `String`     | ❌        | Google Analytics ID                                          |
| `integrationGTM`    | `String`     | ❌        | Google Tag Manager container ID                              |
| `folderId`          | `String`     | ❌        | ID of the folder where the link should be created            |

## 🔐 Secure Short Link

If you want to encrypt the original URL before shortening it. For privacy or security reasons — the SDK provides a utility function called `createSecure`. This function encrypts the original URL using AES-GCM and returns a secured URL with a separate decryption key.

```swift
import ShortIOSDK

let sdk = ShortIOSDK.shared

Task {
    do {
        let result = try sdk.createSecure(originalURL: "your_originalURL_here")
        print("result", result.securedOriginalURL, result.securedShortUrl)
    } catch {
        print("Failed to create secure URL: \(error)")
    }
}
```

### 🔒 Output Format

- `securedOriginalURL` – A URL in the format:

```pgsql
shortsecure://<Base64 encrypted URL>?<Base64 IV>
```

- `securedShortUrl` – A fragment (like `#<Base64 key>`) that must be appended manually to the final short URL for decryption.

## 🔄 Conversion Tracking

Track conversions for your short links to measure campaign effectiveness. The SDK provides a simple method to record conversions.

```swift
import ShortIOSDK

let sdk = ShortIOSDK.shared

Task {
    do {
        let result = try await sdk.trackConversion(
            conversionId: "your_conversionID" // optional
        )
        print("result", result)
    } catch {
        print("Failed to track conversion: \(error)")
    }
}
```

**Note:** `conversionId` is optional. The `clid` is captured automatically by `handleOpen(_:)` when the user opens the link, and the domain comes from `initialize(apiKey:domain:)` — so neither needs to be passed.

**⚠️ Deprecated:** the `trackConversion(clid:domain:conversionId:)` overload still works, but is deprecated as of `1.1.0` and **will be removed in `2.0.0`**. Xcode offers a fix-it to migrate to `trackConversion(conversionId:)`.

## 🌐 Deep Linking Setup (Universal Links for iOS)

To ensure your app can handle deep links created via Short.io, you need to configure Universal Links properly using **Associated Domains** in your Xcode project.

### 🔧 Step 1: Enable Associated Domains

**📌 Note:** You must have an active Apple Developer Account to enable Associated Domains. This requires access to your Team ID and Bundle Identifier.

1. Open your Xcode project.
2. Click on your project name in the **Project Navigator** to open the project settings.
3. Select the **"Signing and Capabilities"** tab.
4. Choose your **Team** from the dropdown (linked to your Developer Account).
5. Ensure your **Bundle Identifier** is correctly set.
6. Click the **+ Capability** button and add **Associated Domains**.

    **✅ Tip:** The **Associated Domains** capability will only appear if you have provided a valid **Team** and **Bundle Identifier**.

7. Under Associated Domains, add your Short.io domain in the following format:

```vbnet
applinks:yourshortdomain.short.gy
```

### 🌐 Step 2: Configure Deep Linking on Short.io

To enable universal link handling, **Short.io** must generate the `apple-app-site-association` file based on your app’s credentials.

1. Go to [Short.io](https://short.io/).
2. Open **Domain Settings** > **Deep links** for the short domain you have specified in Xcode.
3. In the **iOS App Package Name field**, enter your **team** and **bundle ID** in the following format:
```
<your_team_id>.<your_bundle_id>

// Example:
ABCDEFGHIJ.com.example.app
```
4. Click the **Save** button.

## 🛠️ Handling Universal Links in Your App

This guide explains how to handle Universal Links in iOS applications using the SDK's `handleOpen` function. Below are implementation details for both SwiftUI and Storyboard-based projects.

The SDK resolves the short link and returns the `URLComponents` of its **destination** — not of the short link you passed in:

* `url` → The destination URL the short link points to.
* `host` → The destination's host.
* `path` → The destination's path.
* `queryItems` → The destination's query parameters.

### SwiftUI Project

For SwiftUI apps, use the `onOpenURL` modifier at the entry point of your app to process incoming URLs and retrieve the original URL. Below is an example implementation in SwiftUI.

```swift
import SwiftUI
import ShortIOSDK

@main
struct YourApp: App {

    let sdk = ShortIOSDK.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Task {
                        do {
                            let components = try await sdk.handleOpen(url)
                            // Handle successful URL processing
                            print(
                                "Original URL: \(components.url?.absoluteString ?? "unknown")",
                                "Host: \(components.host ?? "nil"), Path: \(components.path)",
                                "QueryParams: \(components.queryItems ?? [])"
                            )
                        } catch {
                            // Handle error with proper error type
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
        }
    }
}

```

### Storyboard Project

For Storyboard-based apps, you can handle incoming Short.io links (Universal Links) in your `SceneDelegate`. Implement the `scene(_:continue:)` method to capture the URL and pass it to the SDK for processing. Below is an example implementation in Storyboard.

```swift
import UIKit
import ShortIOSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private let sdk = ShortIOSDK.shared

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            print("Invalid universal link or URL components")
            return
        }
        Task {
            do {
                let components = try await sdk.handleOpen(incomingURL)
                // Handle successful URL processing
                print(
                    "Original URL: \(components.url?.absoluteString ?? "unknown")",
                    "Host: \(components.host ?? "nil"), Path: \(components.path)",
                    "QueryParams: \(components.queryItems ?? [])"
                )
            } catch {
                // Handle error with proper error type
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
```
### Using the `handleOpen` Function

```swift
public func handleOpen(_ url: URL) async throws -> URLComponents
```

The `handleOpen` function, provided by the SDK, processes a given URL and returns `URLComponents` if the URL is valid. It ensures proper parsing of universal links, checking for a valid scheme and returning all available components for further processing. It also records the link's `clid`, so a later call to `trackConversion` can attribute the conversion without you passing it explicitly.

You can access properties like `host`, `path`, `queryItems`, or other properties from the returned `URLComponents` to determine the appropriate navigation or action in your app.

On failure it throws a `URLHandlerError`:

* `.invalidURLScheme` — the URL is not `http` or `https`.
* `.linkNotValid` — the short link itself was not found (404, no redirect).
* `.destinationUnavailable(statusCode:destination:)` — the short link resolved, but the page it points at returned a failure status. The link is fine; its destination is not.
* `.networkError` — the request failed to complete.

#### ⚠️ Deprecated: completion-handler variant

```swift
@available(*, deprecated, renamed: "handleOpen(_:)")
@MainActor
public func handleOpen(_ url: URL, completion: @escaping URLHandlerCompletion)
```

The completion-handler form still works and still delivers its result on the main thread, so existing integrations continue to compile and behave identically. It is deprecated as of `1.1.0` and **will be removed in `2.0.0`**. Xcode offers a fix-it to migrate to the `async` form above.

### Swift 6 Support

The SDK is built in Swift 6 language mode and is free of data-race diagnostics. `ShortIOSDK` conforms to `Sendable`, so you can hold and call it from any isolation context — including from a `@MainActor` type such as a SwiftUI view — without `@preconcurrency import` or `nonisolated(unsafe)`.

Apps using Swift 5 language mode are unaffected and require no source changes.

#### ⚠️ Minimum deployment target

As of `1.1.0` the package declares a floor of **iOS 15.0 / macOS 12.0**. Earlier releases declared no floor and instead gated the individual `async` methods with `@available`, so an app targeting iOS 13 or 14 could link the SDK and use the completion-handler APIs. That is no longer possible — apps below iOS 15.0 or macOS 12.0 must stay on `1.0.x`.
