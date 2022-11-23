import SwiftUI

struct HStackExample: View {
    var body: some View {
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
}

struct HStackExample_Previews: PreviewProvider {
    static var previews: some View {
        HStackExample()
    }
}
