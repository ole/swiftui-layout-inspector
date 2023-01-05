import Combine
import Dispatch

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class LogStore: ObservableObject {
    @Published public var log: [LogEntry]
    var viewLabels: Set<String> = []

    init(log: [LogEntry] = []) {
        self.log = log
        self.viewLabels = Set(log.map(\.label))
    }

    func registerViewLabelAndWarnIfNotUnique(_ label: String, file: StaticString, line: UInt) {
        DispatchQueue.main.async { [self] in
            if viewLabels.contains(label) {
                let message: StaticString = "%@:%llu: Duplicate view label '%@' detected. Use unique labels in .layoutStep() calls"
                runtimeWarning(message, [String(describing: file), UInt64(line), label], file: file, line: line)
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
