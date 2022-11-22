import CoreGraphics

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGSize {
        CGSize(width: lhs.x + rhs.x, height: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGSize {
        CGSize(width: lhs.x - rhs.x, height: lhs.y - rhs.y)
    }
}

extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
}

extension CGRect {
    var topLeading: CGPoint {
        get { CGPoint(x: minX, y: minY) }
        set {
            let delta = newValue - CGPoint(x: minX, y: minY)
            origin.x += delta.width
            origin.y += delta.height
            size.width -= delta.width
            size.height -= delta.height
            self = self.standardized
        }
    }

    var topTrailing: CGPoint {
        get { CGPoint(x: maxX, y: minY) }
        set {
            let delta = newValue - CGPoint(x: maxX, y: minY)
            origin.y += delta.height
            size.width += delta.width
            size.height -= delta.height
            self = self.standardized
        }
    }

    var bottomLeading: CGPoint {
        get { CGPoint(x: minX, y: maxY) }
        set {
            let delta = newValue - CGPoint(x: minX, y: maxY)
            origin.x += delta.width
            size.width -= delta.width
            size.height += delta.height
            self = self.standardized
        }
    }

    var bottomTrailing: CGPoint {
        get { CGPoint(x: maxX, y: minY) }
        set {
            let delta = newValue - CGPoint(x: maxX, y: minY)
            size.width += delta.width
            size.height += delta.height
            self = self.standardized
        }
    }
}
