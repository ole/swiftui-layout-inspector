import CoreGraphics
import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension CGFloat {
    var pretty: String {
        String(format: "%.1f", self)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension CGSize {
    var pretty: String {
        let thinSpace: Character = "\u{2009}"
        return "\(width.pretty)\(thinSpace)×\(thinSpace)\(height.pretty)"
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension Optional where Wrapped == CGFloat {
    var pretty: String {
        self?.pretty ?? "nil"
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension ProposedViewSize {
    var pretty: String {
        let thinSpace: Character = "\u{2009}"
        return "\(width.pretty)\(thinSpace)×\(thinSpace)\(height.pretty)"
    }
}
