import LayoutInspector
import SwiftUI

struct PaddingExample: View {
    var body: some View {
        Text("Hello world")
            .layoutStep("Text")
            .padding(10)
            .layoutStep("padding")
            .border(Color.green)
            .layoutStep("border")
            .inspectLayout()
    }
}

struct PaddingExample_Previews: PreviewProvider {
    static var previews: some View {
        PaddingExample()
    }
}
