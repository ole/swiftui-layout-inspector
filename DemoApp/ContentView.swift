import LayoutInspector
import SwiftUI

struct ContentView: View {
    var body: some View {
        /// The view tree whose layout you want to inspect. Add `.layoutStep()`
        /// calls at each point where you want to inspect the layout algorithm,
        /// i.e. what sizes are being proposed and returned. We call these
        ///  **inspection points**.
        VStack {
            Inspector {
                hStackExample
            }
        }
    }

    var paddingExample: some View {
        Text("Hello world")
            .layoutStep("Text")
            .padding(10)
            .layoutStep("padding")
            .border(Color.green)
            .layoutStep("border")
    }

    var hStackExample: some View {
        HStack(spacing: 10) {
            Rectangle().fill(.green)
                .layoutStep("green")
            Text("Hello world")
                .layoutStep("Text")
            Rectangle().fill(.yellow)
                .layoutStep("yellow")
        }
        .layoutStep("HStack")
    }

    var fixedSizeExample: some View {
          Text("Lorem ipsum dolor sit amet")
              .layoutStep("Text")
              .fixedSize()
              .layoutStep("fixedSize")
              .frame(width: 100)
              .layoutStep("frame")
              .border(Color.green)
    }
}

struct Inspector<Subject: View>: View {
    @ViewBuilder var subject: Subject

    @State private var width: CGFloat = 300
    @State private var height: CGFloat = 100

    private var roundedWidth: CGFloat { width.rounded() }
    private var roundedHeight: CGFloat { height.rounded() }

    var body: some View {
        VStack {
            VStack {
                subject
                    .inspectLayout()
                    .frame(width: roundedWidth, height: roundedHeight)
                    .overlay {
                        Rectangle()
                            .strokeBorder(style: StrokeStyle(dash: [5]))
                    }

                Spacer()

                VStack {
                    LabeledContent {
                        HStack {
                            Slider(value: $width, in: 0...500)
                            Stepper("Width", value: $width)
                        }
                        .labelsHidden()
                    } label: {
                        Text("W \(roundedWidth, format: .number.precision(.fractionLength(0)))")
                            .monospacedDigit()
                    }

                    LabeledContent {
                        HStack {
                            Slider(value: $height, in: 0...500)
                            Stepper("Height", value: $height)
                        }
                        .labelsHidden()
                    } label: {
                        Text("H \(roundedHeight, format: .number.precision(.fractionLength(0)))")
                            .monospacedDigit()
                    }
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
