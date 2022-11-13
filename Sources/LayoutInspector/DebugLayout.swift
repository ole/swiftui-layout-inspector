import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension View {
    /// Start debugging the layout algorithm for this subtree.
    ///
    /// This clears the debug layout log.
    public func startDebugLayout(selection: String? = nil) -> some View {
        ClearDebugLayoutLog {
            self
        }
        .environment(\.debugLayoutSelectedViewID, selection)
    }

    /// Monitor the layout proposals and responses for this view and add them
    /// to the log.
    public func debugLayout(
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
