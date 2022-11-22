import SwiftUI

extension View {
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func measureSize(onChange: @escaping (CGSize) -> Void) -> some View {
        self
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: geometry.size)
                }
            }
            .onPreferenceChange(SizePreferenceKey.self) { size in
                if let size {
                    onChange(size)
                }
            }
    }
}

enum SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize? = nil

    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        value = value ?? nextValue()
    }
}
