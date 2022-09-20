import SwiftUI

struct ContentView: View {
    @State private var width: CGFloat = 300
    @State private var height: CGFloat = 100
    @State private var selectedView: String? = nil
    @State private var generation: Int = 0

    var subject: some View {
        Text("Hello")
            .debugLayout("Text")
            .aspectRatio(1, contentMode: .fit)
            .debugLayout("aspectRatio")
    }

    var body: some View {
        VStack {
            VStack {
                subject
                    .clearConsole()
                    .environment(\.debugLayoutSelection, selectedView)
                    .frame(width: width, height: height)
                    .overlay {
                        Rectangle()
                            .strokeBorder(style: StrokeStyle(dash: [5]))
                    }
                    .id(generation)
                    .padding(.bottom, 16)

                LabeledContent {
                    Slider(value: $width, in: 50...500, step: 1)
                } label: {
                    Text("Width: \(width, format: .number.precision(.fractionLength(0)))")
                        .monospacedDigit()
                }

                LabeledContent {
                    Slider(value: $height, in: 50...500, step: 1)
                } label: {
                    Text("Height: \(height, format: .number.precision(.fractionLength(0)))")
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
