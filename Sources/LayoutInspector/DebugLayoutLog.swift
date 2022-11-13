import SwiftUI

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

/// A custom layout that clears the DebugLayout log
/// at the point where it's placed in the view tree.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct ClearDebugLayoutLog: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        assert(subviews.count == 1)
        DispatchQueue.main.async {
            LogStore.shared.log.removeAll()
            LogStore.shared.viewLabels.removeAll()
        }
        return subviews[0].sizeThatFits(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        assert(subviews.count == 1)
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class LogStore: ObservableObject {
    public static let shared: LogStore = .init()

    @Published var log: [LogEntry] = []
    var viewLabels: Set<String> = []

    func registerViewLabelAndWarnIfNotUnique(_ label: String, file: StaticString, line: UInt) {
        DispatchQueue.main.async {
            if self.viewLabels.contains(label) {
                let message: StaticString = "Duplicate view label '%s' detected. Use unique labels in debugLayout() calls"
                runtimeWarning(message, [label], file: file, line: line)
            }
            self.viewLabels.insert(label)
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct LogEntry: Identifiable {
    enum Step {
        case proposal(ProposedViewSize)
        case response(CGSize)
        case proposalAndResponse(proposal: ProposedViewSize, response: CGSize)
    }

    var id: UUID = .init()
    var label: String
    var step: Step
    var indent: Int

    var proposal: ProposedViewSize? {
        switch step {
        case .proposal(let p): return p
        case .response(_): return nil
        case .proposalAndResponse(proposal: let p, response: _): return p
        }
    }

    var response: CGSize? {
        switch step {
        case .proposal(_): return nil
        case .response(let r): return r
        case .proposalAndResponse(proposal: _, response: let r): return r
        }
    }
}

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

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct DebugLayoutLogView: View {
    @Binding var selection: String?
    @ObservedObject var logStore: LogStore

    private static let tableRowHorizontalPadding: CGFloat = 8
    private static let tableRowVerticalPadding: CGFloat = 4

    public init(selection: Binding<String?>? = nil, logStore: LogStore = LogStore.shared) {
        if let binding = selection {
            self._selection = binding
        } else {
            var nirvana: String? = nil
            self._selection = Binding(get: { nirvana }, set: { nirvana = $0 })
        }
        self._logStore = ObservedObject(wrappedValue: logStore)
    }

    public var body: some View {
        ScrollView(.vertical) {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 0, verticalSpacing: 0) {
                // Table header row
                GridRow {
                    Text("View")
                    Text("Proposal")
                    Text("Response")
                }
                .font(.headline)
                .padding(.vertical, Self.tableRowVerticalPadding)
                .padding(.horizontal, Self.tableRowHorizontalPadding)

                // Table header separator line
                Rectangle().fill(.secondary)
                    .frame(height: 1)
                    .gridCellUnsizedAxes(.horizontal)
                    .padding(.vertical, Self.tableRowVerticalPadding)
                    .padding(.horizontal, Self.tableRowHorizontalPadding)

                // Table rows
                ForEach(logStore.log) { item in
                    let isSelected = selection == item.label
                    GridRow {
                        HStack(spacing: 0) {
                            indentation(level: item.indent)
                            Text(item.label)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                        Text(item.proposal?.pretty ?? "…")
                            .monospacedDigit()
                            .fixedSize()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                        Text(item.response?.pretty ?? "…")
                            .monospacedDigit()
                            .fixedSize()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                    .font(.callout)
                    .padding(.vertical, Self.tableRowVerticalPadding)
                    .padding(.horizontal, Self.tableRowHorizontalPadding)
                    .foregroundColor(isSelected ? .white : nil)
                    .background(isSelected ? Color.accentColor : .clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selection = isSelected ? nil : item.label
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background {
            #if os(macOS)
            Color(white: 0.8)
            #else
            Color(uiColor: .secondarySystemBackground)
            #endif
        }
    }

    private func indentation(level: Int) -> some View {
        ForEach(0 ..< level, id: \.self) { _ in
            Color.clear
                .frame(width: 16)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .frame(width: 1)
                        .padding(.leading, 4)
                        // Compensate for cell padding, we want continuous vertical lines.
                        .padding(.vertical, -Self.tableRowVerticalPadding)
                }
        }
    }
}
