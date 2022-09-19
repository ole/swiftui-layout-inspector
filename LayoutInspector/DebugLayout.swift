// Based on: Swift Talk 319, Inspecting HStack Layout (2022-08-26)
// <https://talk.objc.io/episodes/S01E319-inspecting-hstack-layout>

import SwiftUI

extension View {
    func debugLayout(_ label: String) -> some View {
        DebugLayout(label: label) { self }
    }
}

struct DebugLayout: Layout {
    var label: String

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        assert(subviews.count == 1)
        log(label, action: "P", value: proposal.pretty)
        let result = subviews[0].sizeThatFits(proposal)
        log(label, action: "⇒", value: result.pretty)
        return result
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
        var id: UUID = .init()
        var label: String
        var action: String
        var value: String
    }
}

func log(_ label: String, action: String, value: String) {
    DispatchQueue.main.async {
        Console.shared.log.append(.init(label: label, action: action, value: value))
    }
}

struct ConsoleView: View {
    @ObservedObject var console = Console.shared

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Layout Log")
                    .font(.headline)

                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(console.log) { item in
                        GridRow {
                            Text(item.label)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(item.action)
                                .font(.headline)

                            Text(item.value)
                                .monospacedDigit()
                                .gridColumnAlignment(.trailing)
                        }

                        Divider()
                            .gridCellUnsizedAxes(.horizontal)
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }
}
