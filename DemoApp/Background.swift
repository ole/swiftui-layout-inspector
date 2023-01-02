import SwiftUI

struct BackgroundExample: View {
    var body: some View {
        Text("Hello world")
            .padding(10)
            .layoutStep("Text and padding")
            .background {
                Color.blue
                    .layoutStep("background child")
            }
            .layoutStep("background")
            .inspectLayout()
    }
}

struct BackgroundExample_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundExample()
    }
}
