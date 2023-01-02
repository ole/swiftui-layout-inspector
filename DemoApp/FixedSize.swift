import SwiftUI

struct FixedSizeExample: View {
    var body: some View {
        Text("Lorem ipsum dolor sit amet")
            .layoutStep("Text")
            .fixedSize()
            .layoutStep("fixedSize")
            .frame(width: 100)
            .layoutStep("frame")
            .border(Color.green)
            .inspectLayout()
    }
}

struct FixedSizeExample_Previews: PreviewProvider {
    static var previews: some View {
        FixedSizeExample()
    }
}
