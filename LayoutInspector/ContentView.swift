import SwiftUI
import DebugLayout

struct ContentView: View {
    var suggestedExamplePadding: some View {
        Text("Hello world")
            .debugLayout("Text")
            .padding(10)
            .debugLayout("padding")
            .border(Color.green)
            .debugLayout("border")

    }

    var hstack: some View {
        HStack(spacing: 10) {
            Rectangle().fill(.green)
                .debugLayout("green")
            Text("Hello world")
                .debugLayout("Text")
            Rectangle().fill(.yellow)
                .debugLayout("yellow")
        }
        .debugLayout("HStack")
    }

    var fixedSize: some View {
          Text("Lorem ipsum dolor sit amet")
              .debugLayout("Text")
              .fixedSize()
              .debugLayout("fixedSize")
              .frame(width: 100)
              .debugLayout("frame")
              .border(Color.green)
      }

    var body: some View {
        Inspector {
            hstack
        }
    }
}

struct Inspector<Subject: View>: View {

    /// The view tree whose layout you want to inspect. Add `.debugLayout()` calls at
    /// each point where you want to inspect the layout algorithm, i.e. what sizes are
    /// being proposed and returned. We call these **inspection points**.
    @ViewBuilder var subject: Subject

    init(@ViewBuilder subject: () -> Subject) {
        self.subject = subject()
    }

    @State private var width: CGFloat = 300
    @State private var height: CGFloat = 100
    @State private var selectedView: String? = nil
    @State private var generation: Int = 0


    var body: some View {
        VStack {
            VStack {
                subject
                    .startDebugLayout(selection: selectedView)
                    .id(generation)
                    .frame(width: width, height: height)
                    .overlay {
                        Rectangle()
                            .strokeBorder(style: StrokeStyle(dash: [5]))
                    }
                    .padding(.bottom, 16)

                VStack {
                    LabeledContent {
                        HStack {
                            Slider(value: $width, in: 50...500, step: 1)
                            Stepper("Width", value: $width)
                        }
                        .labelsHidden()
                    } label: {
                        Text("W \(width, format: .number.precision(.fractionLength(0)))")
                            .monospacedDigit()
                    }

                    LabeledContent {
                        HStack {
                            Slider(value: $height, in: 50...500, step: 1)
                            Stepper("Height", value: $height)
                        }
                        .labelsHidden()
                    } label: {
                        Text("H \(height, format: .number.precision(.fractionLength(0)))")
                            .monospacedDigit()
                    }

                    Button("Reset layout cache") {
                        generation += 1
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()

            DebugLayoutLogView(selection: $selectedView)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
