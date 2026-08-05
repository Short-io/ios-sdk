// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShortIOSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ShortIOSDK",
            targets: ["ShortIOSDK"]),
    ],
    targets: [
        .target(
            name: "ShortIOSDK"),
        .testTarget(
            name: "ShortIOSDKTests",
            dependencies: ["ShortIOSDK"])
    ]
)
