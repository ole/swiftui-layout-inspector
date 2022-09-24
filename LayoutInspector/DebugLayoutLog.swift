import SwiftUI

func logLayoutStep(_ label: String, step: LogItem.Step, indent: Int) {
    DispatchQueue.main.async {
        // Coalesce layout steps if the response follows immediately after the proposal
        // for the same view.
        //
        // In this case, proposal and response can be shown in a single row in the log.
        if var lastLogItem = LogStore.shared.log.last,
           lastLogItem.label == label,
           case .proposal(let proposal) = lastLogItem.step,
           case .response(let response) = step
        {
            LogStore.shared.log.removeLast()
            lastLogItem.step = .proposalAndResponse(proposal: proposal, response: response)
            LogStore.shared.log.append(lastLogItem)
        } else {
            LogStore.shared.log.append(.init(label: label, step: step, indent: indent))
        }
    }
}

/// A custom layout that clears the DebugLayout log
/// at the point where it's placed in the view tree.
struct ClearDebugLayoutLog: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        assert(subviews.count == 1)
        DispatchQueue.main.async {
            LogStore.shared.log.removeAll()
        }
        return subviews[0].sizeThatFits(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        assert(subviews.count == 1)
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

final class LogStore: ObservableObject {
    static let shared: LogStore = .init()

    @Published var log: [LogItem] = []
}

struct LogItem: Identifiable {
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

struct DebugLayoutSelectedViewID: EnvironmentKey {
    static var defaultValue: String? { nil }
}

extension EnvironmentValues {
    var debugLayoutSelectedViewID: String? {
        get { self[DebugLayoutSelectedViewID.self] }
        set { self[DebugLayoutSelectedViewID.self] = newValue }
    }
}

struct DebugLayoutLogView: View {
    @Binding var selection: String?
    @ObservedObject var logStore: LogStore

    private static let tableRowHorizontalPadding: CGFloat = 8
    private static let tableRowVerticalPadding: CGFloat = 4

    init(selection: Binding<String?>? = nil, logStore: LogStore = LogStore.shared) {
        if let binding = selection {
            self._selection = binding
        } else {
            var nirvana: String? = nil
            self._selection = Binding(get: { nirvana }, set: { nirvana = $0 })
        }
        self._logStore = ObservedObject(wrappedValue: logStore)
    }

    var body: some View {
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
        .background(Color(uiColor: .secondarySystemBackground))
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
