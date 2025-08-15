
# ShortLink SDK for iOS (Deep Linking Integration using Short.io)

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

let parameters = ShortIOParameters(
    domain: "your_domain", // Replace with your Short.io domain
    originalURL: "https://{your_domain}"// Replace with your Short.io domain
)
```
**Note**: The `originalURL` are the required parameter. You can also pass optional parameters such as `path`, `title`, `utmParameters`, etc.

- `domain` parameter is deprecated. Use the instance's configured API key instead. Call initialize(apiKey:domain:) before using this method

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
**⚠️ Note**: The `apiKey` parameter is deprecated. Use the instance's configured API key instead. Call initialize(apiKey:domain:) before using this method

## 📄 API Parameters

The `ShortIOParameters` struct is used to define the details of the short link you want to create. Below are the available parameters:


| Parameter           | Type         | Required  | Description                                                  |
| ------------------- | -----------  | --------  | ------------------------------------------------------------ |
| `domain`            | `String`     | ✅ (Deprecated)        | ⚠️ Deprecated. No longer required — inferred from API key. May be removed in future versions.             |
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
            domain: "https://{your_domain}", // ⚠️ Deprecated (optional):
            clid: "your_clid", // ⚠️ Deprecated (optional):
            conversionId: "your_conversionID" (optional)
        )
        print("result", result)
    } catch {
        print("Failed to track conversion: \(error)")
    }
}
```

**⚠️ Note:** All three parameters — `domain`, `clid`, and `conversionId` — are optional.
- `domain` and `clid` are deprecated and may be removed in future versions.

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

### SwiftUI Project

For SwiftUI apps, use the `onOpenURL` modifier at the entry point of your app to process incoming URLs and navigate to the appropriate views. Below is an example implementation in SwiftUI.

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
                    print("url", url)
                    sdk.handleOpen(url) { result in
                        switch result {
                        case .success(let result):
                            // Handle successful URL processing
                            print("result", result, "Host: \(result.host), Path: \(result.path)", "QueryParams: \(result.queryItems)")
                        case .failure(let error):
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

For Storyboard apps, implement the `scene(_:continue:)` method in your `SceneDelegate` to handle Universal Links. Below is an example implementation in Storyboard.

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
        sdk.handleOpen(url) { result in
            switch result {
                case .success(let result):
                    // Handle successful URL processing
                    print("result", result, "Host: \(result.host), Path: \(result.path)", "QueryParams: \(result.queryItems)")
                case .failure(let error):
                    // Handle error with proper error type
                    print("Error: \(error.localizedDescription)")
            }
        }
    }
}
```
### Using the `handleOpen` Function

The `handleOpen` function, provided by the SDK, processes a given URL and returns `URLComponents` if the URL is valid. It ensures proper parsing of universal links, checking for a valid scheme and returning all available components for further processing.

You can access properties like `host`, `path`, `queryItems`, or other properties from the returned `URLComponents` to determine the appropriate navigation or action in your app.
