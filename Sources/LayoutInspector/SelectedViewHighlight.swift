import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct DebugLayoutSelectedViewID: EnvironmentKey {
    static var defaultValue: String? { nil }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension EnvironmentValues {
    var debugLayoutSelectedViewID: String? {
        get { self[DebugLayoutSelectedViewID.self] }
        set { self[DebugLayoutSelectedViewID.self] = newValue }
    }
}

/// Draws a highlight (dashed border) around the view that's selected
/// in the DebugLayout log table.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct DebugLayoutSelectionHighlight: ViewModifier {
    var viewID: String
    @Environment(\.debugLayoutSelectedViewID) private var selection: String?

    func body(content: Content) -> some View {
        content
            .overlay {
                let isSelected = viewID == selection
                if isSelected {
                    Rectangle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.pink)
                }
            }
    }
}
