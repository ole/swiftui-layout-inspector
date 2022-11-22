import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension View {
    /// Inspect the layout for this subtree.
    public func inspectLayout() -> some View {
        self.modifier(InspectLayout())
    }

    /// Monitor the layout proposals and responses for this view and add them
    /// to the log.
    public func layoutStep(
        _ label: String,
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> some View {
        DebugLayout(label: label) {
            self
        }
        .onAppear {
            LogStore.shared.registerViewLabelAndWarnIfNotUnique(label, file: file, line: line)
        }
        .modifier(DebugLayoutSelectionHighlight(viewID: label))
    }
}
