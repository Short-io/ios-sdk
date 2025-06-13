
# ShortLink SDK for iOS (Deep Linking Integration using Short.io)

This SDK allows you to create short links using the [Short.io](https://short.io/) API based on a public API key and custom parameters. It also supports iOS deep linking integration using Universal Links.

## ✨ Features

- Generate short links via Short.io API
- Customize short links using parameters
- Integrate iOS Universal Links (Deep Linking)
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


### Step 1: Get Public API Key from Short.io

1. Visit [Short.io](https://short.io/) and **sign up** or **log in** to your account.
3. In the dashboard, navigate to **Integrations & API**.
4. Click **CREATE API KEY** button.
5. Enable the **Public Key** toggle.
7. Click **CREATE** to generate your API key.

## 🔗 SDK Usage

```swift
import ShortIOSDK



let sdk = ShortIOSDK()

let parameters = ShortIOParameters(
    domain: "your_domain", // Replace with your Short.io domain
    originalURL: "your_originalURL"// Replace with your Short.io domain
)
```
**Note**: Both `domain` and `originalURL` are the required parameters. You can also pass optional parameters such as `path`, `title`, `utmParameters`, etc.

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

## 📄 API Parameters

The `ShortIOParameters` struct is used to define the details of the short link you want to create. Below are the available parameters:


| Parameter           | Type         | Required  | Description                                                  |
| ------------------- | -----------  | --------  | ------------------------------------------------------------ |
| `domain`            | `String`     | ✅        | Your Short.io domain (e.g., `example.short.gy`)              |
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
    
    let sdk = ShortIOSDK()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if let result = sdk.handleOpen(url) {
                        print("Host: \(result.host), Path: \(result.path.split(separator: "/").first)")
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
    
    let sdk = ShortIOSDK()
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = sdk.handleOpen(incomingURL) else {
            print("Invalid universal link or URL components")
            return
        }
        print("Host: \(host), Path: \(components.path.split(separator: "/").first)")
    }
}
```
### Using the `handleOpen` Function

The `handleOpen` function, provided by the SDK, processes a given URL and returns `URLComponents` if the URL is valid. It ensures proper parsing of universal links, checking for a valid scheme and returning all available components for further processing.

You can access properties like `host`, `path`, `queryItems`, or other properties from the returned `URLComponents` to determine the appropriate navigation or action in your app.