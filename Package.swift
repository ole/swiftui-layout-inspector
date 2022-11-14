// swift-tools-version: 5.7

// SwiftUI Layout Inspector
//
// A tool for learning how the SwiftUI layout system works,
// and for debugging your own layout code.
//
// https://github.com/ole/swiftui-layout-inspector/
//
// By Ole Begemann, https://oleb.net/

import PackageDescription

let package = Package(
    name: "LayoutInspector",
    // LayoutInspector requires iOS 16/macOS 13. We specify a lower deployment
    // target here to allow integrating the library into an app with a lower
    // deployment target. The entire LayoutInspector API is availability-gated
    // to iOS 16/macOS 13, though, so you can only use it in views that are
    // `@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)` or higher.
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "LayoutInspector",
            targets: ["LayoutInspector"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(name: "LayoutInspector", dependencies: []),
    ]
)
