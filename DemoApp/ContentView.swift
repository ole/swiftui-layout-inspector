import LayoutInspector
import SwiftUI

struct ContentView: View {
    var body: some View {
        Inspector {
            /// The view tree whose layout you want to inspect. Add `.debugLayout()` calls at
            /// each point where you want to inspect the layout algorithm, i.e. what sizes are
            /// being proposed and returned. We call these **inspection points**.
            hStackExample
        }
    }

    var paddingExample: some View {
        Text("Hello world")
            .debugLayout("Text")
            .padding(10)
            .debugLayout("padding")
            .border(Color.green)
            .debugLayout("border")
    }

    var hStackExample: some View {
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

    var fixedSizeExample: some View {
          Text("Lorem ipsum dolor sit amet")
              .debugLayout("Text")
              .fixedSize()
              .debugLayout("fixedSize")
              .frame(width: 100)
              .debugLayout("frame")
              .border(Color.green)
    }
}

struct Inspector<Subject: View>: View {
    @ViewBuilder var subject: Subject

    @State private var width: CGFloat = 300
    @State private var height: CGFloat = 100
    @State private var selectedView: String? = nil
    @State private var generation: Int = 0
    @ObservedObject private var logStore = LogStore.shared

    private var roundedWidth: CGFloat { width.rounded() }
    private var roundedHeight: CGFloat { height.rounded() }

    var body: some View {
        VStack {
            VStack {
                subject
                    .startDebugLayout(selection: selectedView)
                    .id(generation)
                    .frame(width: roundedWidth, height: roundedHeight)
                    .overlay {
                        Rectangle()
                            .strokeBorder(style: StrokeStyle(dash: [5]))
                    }
                    .padding(.bottom, 16)

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

                    Button("Reset layout cache") {
                        generation += 1
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()

            #if os(macOS)
            LogEntriesTable(logEntries: logStore.log, highlight: $selectedView)
            #else
            LogEntriesGrid(logEntries: logStore.log, highlight: $selectedView)
            #endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
