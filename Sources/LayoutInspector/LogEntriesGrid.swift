import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct LogEntriesGrid: View {
    @ObservedObject var logStore: LogStore
    @Binding var highlight: String?

    private static let tableRowHorizontalPadding: CGFloat = 8
    private static let tableRowVerticalPadding: CGFloat = 4

    public init(logStore: LogStore, highlight: Binding<String?>? = nil) {
        self._logStore = ObservedObject(initialValue: logStore)
        if let binding = highlight {
            self._highlight = binding
        } else {
            var nirvana: String? = nil
            self._highlight = Binding(get: { nirvana }, set: { nirvana = $0 })
        }
    }

    public var body: some View {
        Grid(
            alignment: .leadingFirstTextBaseline,
            horizontalSpacing: 0,
            verticalSpacing: 0
        ) {
            // Table header row
            GridRow {
                Text("View")
                Text("Proposal")
                Text("Response")
            }
            .bold()
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
                let isSelected = highlight == item.label
                GridRow {
                    HStack(spacing: 0) {
                        indentation(level: item.indent)
                        Text(item.label)
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
                .padding(.vertical, Self.tableRowVerticalPadding)
                .padding(.horizontal, Self.tableRowHorizontalPadding)
                .foregroundColor(isSelected ? .white : nil)
                .background(isSelected ? Color.accentColor : .clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    highlight = isSelected ? nil : item.label
                }
            }
        }
        .padding(.vertical, 8)
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

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct LogEntriesGrid_Previews: PreviewProvider {
    static var previews: some View {
        let logStore = LogStore(log: sampleLogEntries)
        LogEntriesGrid(logStore: logStore)
    }
}
