import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension View {
    /// Inspect the layout for this subtree.
    @MainActor public func inspectLayout() -> some View {
        modifier(InspectLayout())
    }

    /// Monitor the layout proposals and responses for this view and add them
    /// to the log.
    @MainActor public func layoutStep(
        _ label: String,
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> some View {
        modifier(DebugLayoutModifier(label: label, file: file, line: line))
    }
}
