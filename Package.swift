// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "LayoutInspector",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)],
    products: [
        .library(name: "LayoutInspector", targets: ["LayoutInspector"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "LayoutInspector", dependencies: []),
    ]
)
