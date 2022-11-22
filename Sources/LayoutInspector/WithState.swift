#if canImport(SwiftUI)

import SwiftUI

/// A wrapper view that takes a constant value and provides it to its child as a mutable `Binding`.
///
/// Useful in Previews for previewing views that require a binding. You can't easily declare a
/// `@State` variable in a PreviewProvider, and a `Binding.constant` doesn’t always cut it if you
/// want to test a view’s dynamic behavior.
///
/// Example:
///
///     struct InteractiveStepper_Previews: PreviewProvider {
///       static var previews: some View {
///         WithState(5) { counterBinding in
///           Stepper(value: counterBinding, in: 0...10) {
///             Text("Counter: \(counterBinding.wrappedValue)")
///           }
///         }
///       }
///     }
///
public struct WithState<Value, Content: View>: View {
  @State private var value: Value
  let content: (Binding<Value>) -> Content
  
  public init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
    self._value = State(wrappedValue: value)
    self.content = content
  }

  public var body: some View {
    content($value)
  }
}

struct StatefulWrapper_Previews: PreviewProvider {
  static var previews: some View {
    WithState(5) { counterBinding in
      Stepper(value: counterBinding, in: 0...10) {
        Text("Counter: \(counterBinding.wrappedValue)")
      }
      .padding()
    }
  }
}

#endif
