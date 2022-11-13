# DebugLayout

Ole Begemann, 2022-09

Based on: [objc.io, Swift Talk episode 318, Inspecting SwiftUI's Layout Process (2022-08)](https://talk.objc.io/episodes/S01E318-inspecting-swiftui-s-layout-process)

Inspect the layout algorithm of SwiftUI views, i.e. what sizes views propose to
their children and what sizes they return to their parents.

## Requirements

iOS 16.0 or macOS 13.0 (requires the `Layout` protocol).

## Instructions

1.  `import DebugLayout`
    
2.  Add `.debugLayout()` at each point in a view tree where you want to inspect
    the layout algorithm (what sizes are being proposed and returned).
    
3.  At the top of the view tree you want to inspect, add `.startDebugLayout()`.

See the README of the sample app for a complete example.
