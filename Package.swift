// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "DebugLayout",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)],
    products: [
        .library(name: "DebugLayout", targets: ["DebugLayout"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "DebugLayout", dependencies: []),
    ]
)
