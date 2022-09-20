// Based on: Swift Talk 319, Inspecting HStack Layout (2022-08-26)
// <https://talk.objc.io/episodes/S01E319-inspecting-hstack-layout>

import SwiftUI

extension View {
    func debugLayout(_ label: String) -> some View {
        DebugLayout(label: label) {
            self
        }
        .modifier(DebugLayoutWrapper(label: label))
    }
}

struct DebugLayoutWrapper: ViewModifier {
    var label: String
    @Environment(\.debugLayoutSelection) private var selection: String?

    func body(content: Content) -> some View {
        content
            .overlay {
                let isSelected = label == selection
                if isSelected {
                    Rectangle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(.pink)
                }
            }
    }
}

struct DebugLayout: Layout {
    var label: String

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        assert(subviews.count == 1)
        log(label, action: .proposal(proposal))
        let response = subviews[0].sizeThatFits(proposal)
        log(label, action: .response(response))
        return response
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

extension CGFloat {
    var pretty: String {
        String(format: "%.1f", self)
    }
}

extension CGSize {
    var pretty: String {
        let thinSpace: Character = "\u{2009}"
        return "\(width.pretty)\(thinSpace)×\(thinSpace)\(height.pretty)"
    }
}

extension Optional where Wrapped == CGFloat {
    var pretty: String {
        self?.pretty ?? "nil"
    }
}

extension ProposedViewSize {
    var pretty: String {
        let thinSpace: Character = "\u{2009}"
        return "\(width.pretty)\(thinSpace)×\(thinSpace)\(height.pretty)"
    }
}

struct ClearConsole: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        assert(subviews.count == 1)
        DispatchQueue.main.async {
            Console.shared.log.removeAll()
        }
        return subviews[0].sizeThatFits(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

extension View {
    func clearConsole() -> some View {
        ClearConsole { self }
    }
}

final class Console: ObservableObject {
    static let shared: Console = .init()

    @Published var log: [LogItem] = []

    struct LogItem: Identifiable {
        enum Action {
            case proposal(ProposedViewSize)
            case response(CGSize)
            case proposalAndResponse(proposal: ProposedViewSize, response: CGSize)
        }

        var id: UUID = .init()
        var label: String
        var action: Action

        var proposal: ProposedViewSize? {
            switch action {
            case .proposal(let p): return p
            case .response(_): return nil
            case .proposalAndResponse(proposal: let p, response: _): return p
            }
        }

        var response: CGSize? {
            switch action {
            case .proposal(_): return nil
            case .response(let r): return r
            case .proposalAndResponse(proposal: _, response: let r): return r
            }
        }
    }
}

func log(_ label: String, action: Console.LogItem.Action) {
    DispatchQueue.main.async {
        if var lastLogItem = Console.shared.log.last,
           lastLogItem.label == label,
           case .proposal(let proposal) = lastLogItem.action,
           case .response(let response) = action
        {
            Console.shared.log.removeLast()
            lastLogItem.action = .proposalAndResponse(proposal: proposal, response: response)
            Console.shared.log.append(lastLogItem)
        } else {
            Console.shared.log.append(.init(label: label, action: action))
        }
    }
}

struct DebugLayoutSelection: EnvironmentKey {
    static var defaultValue: String? { nil }
}

extension EnvironmentValues {
    var debugLayoutSelection: String? {
        get { self[DebugLayoutSelection.self] }
        set { self[DebugLayoutSelection.self] = newValue }
    }
}

struct Selection<Value: Equatable>: PreferenceKey {
    static var defaultValue: Value? { nil }

    static func reduce(value: inout Value?, nextValue: () -> Value?) {
        value = value ?? nextValue()
    }
}

struct ConsoleView: View {
    @ObservedObject var console = Console.shared
    @State private var selection: String? = nil

    var body: some View {
        ScrollView(.vertical) {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    Text("View")
                    Text("Proposal")
                    Text("Response")
                }
                .font(.headline)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)

                Rectangle().fill(.secondary)
                    .frame(height: 1)
                    .gridCellUnsizedAxes(.horizontal)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)

                ForEach(console.log) { item in
                    let isSelected = selection == item.label
                    GridRow {
                        Text(item.label)
                            .font(.body)
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
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
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
        .preference(key: Selection.self, value: selection)
    }
}
