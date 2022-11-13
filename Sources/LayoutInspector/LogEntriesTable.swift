import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct LogEntriesTable: View {
    var logEntries: [LogEntry]
    @Binding var highlight: String?
    @State private var selectedRow: LogEntry.ID? = nil

    public init(logEntries: [LogEntry], highlight: Binding<String?>? = nil) {
        self.logEntries = logEntries
        if let binding = highlight {
            self._highlight = binding
        } else {
            var nirvana: String? = nil
            self._highlight = Binding(get: { nirvana }, set: { nirvana = $0 })
        }
    }

    public var body: some View {
        Table(logEntries, selection: $selectedRow) {
            TableColumn("View") { item in
                let shouldHighlight = highlight == item.label
                HStack {
                    indentation(level: item.indent)
                    Text(item.label)
                    Image(systemName: "circle.fill")
                        .font(Font.caption2)
                        .foregroundStyle(.tint)
                        .opacity(shouldHighlight ? 1 : 0)
                }
            }
            TableColumn("Proposal") { item in
                Text(item.proposal?.pretty ?? "…")
                    .monospacedDigit()
                    .fixedSize()
                    .foregroundStyle(.primary)
            }
            TableColumn("Response") { item in
                Text(item.response?.pretty ?? "…")
                    .monospacedDigit()
                    .fixedSize()
                    .foregroundStyle(.primary)
            }
        }
        .onChange(of: highlight) { viewLabel in
            let selectedLogEntry = logEntries.first { $0.id == selectedRow }
            if viewLabel != selectedLogEntry?.label {
                selectedRow = nil
            }
        }
        .onChange(of: selectedRow) { rowID in
            let selectedLogEntry = logEntries.first { $0.id == rowID }
            highlight = selectedLogEntry?.label
        }
        .font(.callout)
    }

    private func indentation(level: Int) -> some View {
        ForEach(0 ..< level, id: \.self) { _ in
            Color.clear
                .frame(width: 12)
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct LogEntriesTable_Previews: PreviewProvider {
    static var previews: some View {
        LogEntriesTable(logEntries: sampleLogEntries)
    }
}
