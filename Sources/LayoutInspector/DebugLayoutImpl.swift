import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct InspectLayout: ViewModifier {
    // Don't observe LogStore. Avoids an infinite update loop.
    var logStore: LogStore
    @State private var selectedView: String? = nil
    @State private var generation: Int = 0
    @State private var inspectorFrame: CGRect = CGRect(x: 0, y: 0, width: 300, height: 300)
    @State private var contentSize: CGSize? = nil
    @State private var tableSize: CGSize? = nil
    @State private var isPresentingInfoPanel: Bool = false

    private static let coordSpaceName = "InspectLayout"

    func body(content: Content) -> some View {
        ClearDebugLayoutLog(actions: logStore.actions) {
            content
                .id(generation)
                .environment(\.debugLayoutSelectedViewID, selectedView)
                .measureSize { size in
                    // Move inspector UI below the inspected view initially
                    if contentSize == nil {
                        inspectorFrame.origin.y = size.height + 8
                    }
                    contentSize = size
                }
        }
        .overlay(alignment: .topLeading) {
            inspectorUI
                .frame(width: inspectorFrame.width, height: inspectorFrame.height)
                .offset(x: inspectorFrame.minX, y: inspectorFrame.minY)
                .coordinateSpace(name: Self.coordSpaceName)
        }
        .environment(\.debugLayoutActions, logStore.actions)
    }

    @ViewBuilder private var inspectorUI: some View {
        ScrollView([.vertical, .horizontal]) {
            LogEntriesGrid(logStore: logStore, highlight: $selectedView)
                .measureSize { size in
                    tableSize = size
                }
        }
        .frame(maxWidth: tableSize?.width, maxHeight: tableSize?.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .safeAreaInset(edge: .bottom) {
            toolbar
        }
        .font(.subheadline)
        .resizableAndDraggable(
            frame: $inspectorFrame,
            coordinateSpace: .named(Self.coordSpaceName)
        )
        .background {
            Rectangle().fill(.thickMaterial)
                .shadow(radius: 5)
        }
        .cornerRadius(4)
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.quaternary)
        }
    }

    @ViewBuilder private var toolbar: some View {
        HStack {
            Button("Reset layout cache") {
                generation &+= 1
            }
            Spacer()
            Button {
                isPresentingInfoPanel.toggle()
            } label: {
                Image(systemName: "info.circle")
            }
            .popover(isPresented: $isPresentingInfoPanel) {
                VStack(alignment: .leading) {
                    Text("SwiftUI Layout Inspector")
                        .font(.headline)
                    Link("GitHub", destination: URL(string: "https://github.com/ole/swiftui-layout-inspector")!)
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background()
        .backgroundStyle(.thinMaterial)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct DebugLayoutModifier: ViewModifier {
    var label: String
    var file: StaticString
    var line: UInt
    @Environment(\.debugLayoutActions) var actions: DebugLayoutActions?

    func body(content: Content) -> some View {
        if let actions {
            DebugLayout(label: label, actions: actions) {
                content
            }
            .onAppear {
                actions.registerViewLabelAndWarnIfNotUnique(label, file, line)
            }
            .modifier(DebugLayoutSelectionHighlight(viewID: label))
        } else {
            let _ = runtimeWarning("%@:%llu: Calling .layoutStep() without a matching .inspectLayout() is illegal. Add .inspectLayout() as an ancestor of the view tree you want to inspect.", [String(describing: file), UInt64(line)], file: file, line: line)
            content
        }
    }
}

/// A custom layout that saves the layout proposals and responses for a view
/// to a log.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct DebugLayout: Layout {
    var label: String
    var actions: DebugLayoutActions

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        assert(subviews.count == 1)
        actions.logLayoutStep(label, .proposal(proposal))
        let response = subviews[0].sizeThatFits(proposal)
        actions.logLayoutStep(label, .response(response))
        return response
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

/// A custom layout that clears the DebugLayout log at the point where it's
/// placed in the view tree.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct ClearDebugLayoutLog: Layout {
    var actions: DebugLayoutActions

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        assert(subviews.count == 1)
        DispatchQueue.main.async {
            actions.clearLog()
        }
        return subviews[0].sizeThatFits(proposal)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        assert(subviews.count == 1)
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}
