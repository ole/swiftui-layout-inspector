import SwiftUI

struct ContentView: View {
    @State private var width: CGFloat = 300
    @State private var selectedView: String? = nil
    @State private var generation: Int = 0

    var subject: some View {
        HStack {
            Rectangle().fill(.green)
                .debugLayout("green")
            Text("Hello world")
                .debugLayout("Text")
            Rectangle().fill(.yellow)
                .debugLayout("yellow")
        }
        .debugLayout("HStack")
    }

    var body: some View {
        VStack {
            VStack(spacing: 24) {
                subject
                    .clearConsole()
                    .environment(\.debugLayoutSelection, selectedView)
                    .frame(width: width, height: 80)
                    .id(generation)

                LabeledContent {
                    Slider(value: $width, in: 100...500, step: 1)
                } label: {
                    Text("Width: \(width, format: .number.precision(.fractionLength(0)))")
                        .monospacedDigit()
                }

                Button("Reset layout cache") {
                    generation += 1
                }
                .buttonStyle(.bordered)
            }
            .padding()

            ConsoleView()
                .onPreferenceChange(Selection.self) { selection in
                    selectedView = selection
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
