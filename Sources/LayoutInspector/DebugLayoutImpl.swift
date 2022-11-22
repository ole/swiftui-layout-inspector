import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct InspectLayout: ViewModifier {
    @State private var selectedView: String? = nil
    @State private var generation: Int = 0
    @State private var frame: CGRect = CGRect(x: 0, y: 0, width: 300, height: 300)
    @ObservedObject private var logStore = LogStore.shared

    private static let coordSpaceName = "InspectLayout"

    func body(content: Content) -> some View {
        ClearDebugLayoutLog {
            content
                .id(generation)
                .environment(\.debugLayoutSelectedViewID, selectedView)
        }
        .overlay(alignment: .topLeading) {
            LogEntriesGrid(logEntries: logStore.log, highlight: $selectedView)
                .safeAreaInset(edge: .bottom) {
                    Button("Reset layout cache") {
                        generation += 1
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
    }
}

extension View {
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func resizableAndDraggable(
        frame: Binding<CGRect>,
        coordinateSpace: CoordinateSpace
    ) -> some View {
        modifier(ResizableAndDraggableFrame(
            frame: frame,
            coordinateSpace: coordinateSpace
        ))
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct ResizableAndDraggableFrame: ViewModifier {
    @Binding var frame: CGRect
    var coordinateSpace: CoordinateSpace

    @State private var isDragging: Bool = false
    @State private var isResizing: Bool = false

    private static let chromeWidth: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 20)
            .overlay {
                ZStack(alignment: .top) {
                    Rectangle()
                        .frame(height: 20)
                        .foregroundStyle(isDragging ? .pink : .yellow)
                        .draggable(isDragging: $isDragging, point: $frame.origin, coordinateSpace: coordinateSpace)

                    let resizeHandle = Rectangle()
                        .fill(.green)
                        .frame(width: 20, height: 20)
                    resizeHandle
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .draggable(isDragging: $isResizing, point: $frame.topLeading, coordinateSpace: coordinateSpace)
                    resizeHandle
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .draggable(isDragging: $isResizing, point: $frame.topTrailing, coordinateSpace: coordinateSpace)
                    resizeHandle
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .draggable(isDragging: $isResizing, point: $frame.bottomLeading, coordinateSpace: coordinateSpace)
                    resizeHandle
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .draggable(isDragging: $isResizing, point: $frame.bottomTrailing, coordinateSpace: coordinateSpace)
                }
            }

    }
}

extension Binding {
    func transform<Target>(
        getter: @escaping (Value) -> Target,
        setter: @escaping (inout Value, Target, Transaction) -> Void
    ) -> Binding<Target> {
        Binding<Target>(
            get: { getter(self.wrappedValue) },
            set: { newValue, transaction in
                setter(&self.wrappedValue, newValue, transaction)
            }
        )
    }
}

extension View {
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func draggable(isDragging: Binding<Bool>, offset: Binding<CGSize>, coordinateSpace: CoordinateSpace) -> some View {
        modifier(Draggable(isDragging: isDragging, offset: offset, coordinateSpace: coordinateSpace))
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func draggable(isDragging: Binding<Bool>, point pointBinding: Binding<CGPoint>, coordinateSpace: CoordinateSpace) -> some View {
        let sizeBinding = pointBinding.transform(
            getter: { pt -> CGSize in CGSize(width: pt.x, height: pt.y) },
            setter: { pt, newValue, _ in
                pt = CGPoint(x: newValue.width, y: newValue.height)
            }
        )
        return draggable(isDragging: isDragging, offset: sizeBinding, coordinateSpace: coordinateSpace)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct Draggable: ViewModifier {
    @Binding var isDragging: Bool
    @Binding var offset: CGSize
    var coordinateSpace: CoordinateSpace

    @State private var lastTranslation: CGSize? = nil

    func body(content: Content) -> some View {
        content
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: coordinateSpace)
            .onChanged { gv in
                isDragging = true
                if let last = lastTranslation {
                    let delta = gv.translation - last
                    offset = offset + delta
                    lastTranslation = gv.translation
                } else {
                    lastTranslation = gv.translation
                }
            }
            .onEnded { gv in
                lastTranslation = nil
                isDragging = false
            }
    }
}

/// A custom layout that saves the layout proposals and responses for a view
/// to a log.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct DebugLayout: Layout {
    var label: String

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        assert(subviews.count == 1)
        logLayoutStep(label, step: .proposal(proposal))
        let response = subviews[0].sizeThatFits(proposal)
        logLayoutStep(label, step: .response(response))
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
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        assert(subviews.count == 1)
        DispatchQueue.main.async {
            LogStore.shared.log.removeAll()
            LogStore.shared.viewLabels.removeAll()
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
func logLayoutStep(_ label: String, step: LogEntry.Step) {
    DispatchQueue.main.async {
        guard let prevEntry = LogStore.shared.log.last else {
            // First log entry → start at indent 0.
            LogStore.shared.log.append(LogEntry(label: label, step: step, indent: 0))
            return
        }

        var newEntry = LogEntry(label: label, step: step, indent: prevEntry.indent)
        let isSameView = prevEntry.label == label
        switch (isSameView, prevEntry.step, step) {
        case (true, .proposal(let prop), .response(let resp)):
            // Response follows immediately after proposal for the same view.
            // → We want to display them in a single row.
            // → Coalesce both layout steps.
            LogStore.shared.log.removeLast()
            newEntry = prevEntry
            newEntry.step = .proposalAndResponse(proposal: prop, response: resp)
            LogStore.shared.log.append(newEntry)

        case (_, .proposal, .proposal):
            // A proposal follows a proposal → nested view → increment indent.
            newEntry.indent += 1
            LogStore.shared.log.append(newEntry)

        case (_, .response, .response),
            (_, .proposalAndResponse, .response):
            // A response follows a response → last child returns to parent → decrement indent.
            newEntry.indent -= 1
            LogStore.shared.log.append(newEntry)

        default:
            // Keep current indentation.
            LogStore.shared.log.append(newEntry)
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class LogStore: ObservableObject {
    public static let shared: LogStore = .init()

    @Published public var log: [LogEntry] = []
    var viewLabels: Set<String> = []

    func registerViewLabelAndWarnIfNotUnique(_ label: String, file: StaticString, line: UInt) {
        DispatchQueue.main.async {
            if self.viewLabels.contains(label) {
                let message: StaticString = "Duplicate view label '%s' detected. Use unique labels in layoutStep() calls"
                runtimeWarning(message, [label], file: file, line: line)
            }
            self.viewLabels.insert(label)
        }
    }
}
