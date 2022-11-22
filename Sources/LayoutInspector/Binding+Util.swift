import SwiftUI

extension Binding {
    func transform<Target>(
        getter: @escaping (Value) -> Target,
        setter: @escaping (inout Value, Target, Transaction) -> Void
    ) -> Binding<Target> {
        Binding<Target>(
            get: { getter(self.wrappedValue) },
            set: { newValue, transaction in
                setter(&self.wrappedValue, newValue, transaction)
            }
        )
    }
}
