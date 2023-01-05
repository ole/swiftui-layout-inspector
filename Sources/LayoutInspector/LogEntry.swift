import SwiftUI

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
let sampleLogEntries: [LogEntry] = [
    .init(
        label: "HStack",
        step: .proposal(.init(width: 300, height: 100)),
        indent: 0
    ),
    .init(
        label: "Text",
        step: .proposalAndResponse(
            proposal: .init(width: 0, height: 100),
            response: .init(width: 0, height: 86.3)),
        indent: 1
    ),
    .init(
        label: "Text",
        step: .proposalAndResponse(
            proposal: .init(width: .infinity, height: 100),
            response: .init(width: 85.3, height: 20.3)
        ),
        indent: 1
    ),
    .init(
        label: "green",
        step: .proposalAndResponse(
            proposal: .init(width: 0, height: 100),
            response: .init(width: 0, height: 100)
        ),
        indent: 1
    ),
    .init(
        label: "green",
        step: .proposalAndResponse(
            proposal: .init(width: .infinity, height: 100),
            response: .init(width: CGFloat.infinity, height: 100)
        ),
        indent: 1
    ),
    .init(
        label: "yellow",
        step: .proposalAndResponse(
            proposal: .init(width: 0, height: 100),
            response: .init(width: 0, height: 100)
        ),
        indent: 1
    ),
    .init(
        label: "yellow",
        step: .proposalAndResponse(
            proposal: .init(width: .infinity, height: 100),
            response: .init(width: CGFloat.infinity, height: 100)
        ),
        indent: 1
    ),
    .init(
        label: "Text",
        step: .proposalAndResponse(
            proposal: .init(width: 93.3, height: 100),
            response: .init(width: 85.3, height: 20.3)
        ),
        indent: 1
    ),
    .init(
        label: "green",
        step: .proposalAndResponse(
            proposal: .init(width: 97.3, height: 100),
            response: .init(width: 97.3, height: 100)
        ),
        indent: 1
    ),
    .init(
        label: "yellow",
        step: .proposalAndResponse(
            proposal: .init(width: 97.3, height: 100),
            response: .init(width: 97.3, height: 100)
        ),
        indent: 1
    ),
    .init(
        label: "HStack",
        step: .response(.init(width: 300, height: 100)),
        indent: 0
    ),
]
