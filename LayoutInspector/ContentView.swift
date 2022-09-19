import SwiftUI

struct ContentView: View {
    @State var width: CGFloat = 300

    var body: some View {
        VStack {
            VStack(spacing: 50) {
                HStack(spacing: 0) {
                    Rectangle().fill(.green)
                        .debugLayout("green")
                    Text("Hello world")
                        .debugLayout("Text")
                    Rectangle().fill(.yellow)
                        .debugLayout("yellow")
                }
                .debugLayout("HStack")
                .clearConsole()
                .frame(width: width, height: 80)

                LabeledContent {
                    Slider(value: $width, in: 100...500, step: 1)
                } label: {
                    Text("Width: \(width, format: .number.precision(.fractionLength(0)))")
                        .monospacedDigit()
                }
            }
            .padding()

            ConsoleView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
