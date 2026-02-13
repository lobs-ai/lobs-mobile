// swift-tools-version: 5.9
// This file provides basic SPM structure, but the real app will be opened in Xcode as an iOS app.

import PackageDescription

let package = Package(
    name: "LobsMobile",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LobsMobile",
            targets: ["LobsMobile"]
        )
    ],
    targets: [
        .target(
            name: "LobsMobile",
            path: "LobsMobile"
        )
    ]
)
