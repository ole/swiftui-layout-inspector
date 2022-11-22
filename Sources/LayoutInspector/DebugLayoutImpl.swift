import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct InspectLayout: ViewModifier {
    @StateObject private var logStore: LogStore = .init()
    @State private var selectedView: String? = nil
    @State private var generation: Int = 0
    @State private var frame: CGRect = CGRect(x: 0, y: 0, width: 300, height: 300)

    private static let coordSpaceName = "InspectLayout"

    func body(content: Content) -> some View {
        ClearDebugLayoutLog(logStore: logStore) {
            content
                .id(generation)
                .environment(\.debugLayoutSelectedViewID, selectedView)
        }
        .overlay(alignment: .topLeading) {
            LogEntriesGrid(logEntries: logStore.log, highlight: $selectedView)
                .safeAreaInset(edge: .bottom) {
                    Button("Reset layout cache") {
                        generation &+= 1
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .background()
                    .backgroundStyle(.thickMaterial)
                }
                .resizableAndDraggable(
                    frame: $frame,
                    coordinateSpace: .named(Self.coordSpaceName)
                )
                .background {
                    Rectangle()
                        .fill(.thickMaterial)
                        .shadow(radius: 5)
                }
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: frame.minY)
                .coordinateSpace(name: Self.coordSpaceName)
        }
        .environmentObject(logStore)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct DebugLayoutModifier: ViewModifier {
    var label: String
    var file: StaticString
    var line: UInt
    @EnvironmentObject private var logStore: LogStore

    func body(content: Content) -> some View {
        DebugLayout(label: label, logStore: logStore) {
            content
        }
        .onAppear {
            logStore.registerViewLabelAndWarnIfNotUnique(label, file: file, line: line)
        }
        .modifier(DebugLayoutSelectionHighlight(viewID: label))
    }
}

/// A custom layout that saves the layout proposals and responses for a view
/// to a log.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct DebugLayout: Layout {
    var label: String
    var logStore: LogStore

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        assert(subviews.count == 1)
        logStore.logLayoutStep(label, step: .proposal(proposal))
        let response = subviews[0].sizeThatFits(proposal)
        logStore.logLayoutStep(label, step: .response(response))
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
    var logStore: LogStore

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        assert(subviews.count == 1)
        DispatchQueue.main.async {
            logStore.log.removeAll()
            logStore.viewLabels.removeAll()
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

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class LogStore: ObservableObject {
    @Published public var log: [LogEntry] = []
    var viewLabels: Set<String> = []

    func registerViewLabelAndWarnIfNotUnique(_ label: String, file: StaticString, line: UInt) {
        DispatchQueue.main.async { [self] in
            if viewLabels.contains(label) {
                let message: StaticString = "Duplicate view label '%s' detected. Use unique labels in layoutStep() calls"
                runtimeWarning(message, [label], file: file, line: line)
            }
            viewLabels.insert(label)
        }
    }

    func logLayoutStep(_ label: String, step: LogEntry.Step) {
        DispatchQueue.main.async { [self] in
            guard let prevEntry = log.last else {
                // First log entry → start at indent 0.
                log.append(LogEntry(label: label, step: step, indent: 0))
                return
            }

            var newEntry = LogEntry(label: label, step: step, indent: prevEntry.indent)
            let isSameView = prevEntry.label == label
            switch (isSameView, prevEntry.step, step) {
            case (true, .proposal(let prop), .response(let resp)):
                // Response follows immediately after proposal for the same view.
                // → We want to display them in a single row.
                // → Coalesce both layout steps.
                log.removeLast()
                newEntry = prevEntry
                newEntry.step = .proposalAndResponse(proposal: prop, response: resp)
                log.append(newEntry)

            case (_, .proposal, .proposal):
                // A proposal follows a proposal → nested view → increment indent.
                newEntry.indent += 1
                log.append(newEntry)

            case (_, .response, .response),
                (_, .proposalAndResponse, .response):
                // A response follows a response → last child returns to parent → decrement indent.
                newEntry.indent -= 1
                log.append(newEntry)

            default:
                // Keep current indentation.
                log.append(newEntry)
            }
        }
    }
}
