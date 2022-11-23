import SwiftUI

extension View {
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func resizableAndDraggable(
        frame: Binding<CGRect>,
        coordinateSpace: CoordinateSpace
    ) -> some View {
        modifier(ResizableAndDraggableFrame(
            frame: frame,
            coordinateSpace: coordinateSpace
        ))
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct ResizableAndDraggableFrame: ViewModifier {
    @Binding var frame: CGRect
    var coordinateSpace: CoordinateSpace

    private static let titleBarHeight: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(.top, Self.titleBarHeight)
            .overlay {
                ZStack(alignment: .top) {
                    titleBar
                    resizeHandles
                }
            }
    }

    @ViewBuilder private var titleBar: some View {
        Rectangle()
            .frame(height: Self.titleBarHeight)
            .foregroundStyle(.ultraThinMaterial)
            .overlay {
                Text("Layout Inspector")
                    .font(.footnote)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .foregroundStyle(.quaternary)
                    .frame(height: 1)
            }
            .draggable(point: $frame.origin, coordinateSpace: coordinateSpace)
            .help("Move")
    }

    @ViewBuilder private var resizeHandles: some View {
        let resizeHandle = TriangleStripes()
            .fill(Color(white: 0.5).opacity(0.5))
            .frame(width: 15, height: 15)
            .frame(width: Self.titleBarHeight, height: Self.titleBarHeight, alignment: .topLeading)
            .contentShape(Rectangle())
            .help("Resize")
        resizeHandle
            .draggable(point: $frame.topLeading, coordinateSpace: coordinateSpace)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        resizeHandle
            .rotationEffect(.degrees(90))
            .draggable(point: $frame.topTrailing, coordinateSpace: coordinateSpace)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        resizeHandle
            .rotationEffect(.degrees(-90))
            .draggable(point: $frame.bottomLeading, coordinateSpace: coordinateSpace)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        resizeHandle
            .rotationEffect(.degrees(180))
            .draggable(point: $frame.bottomTrailing, coordinateSpace: coordinateSpace)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

struct TriangleStripes: Shape {
    func path(in rect: CGRect) -> Path {
        let stripeCount = 4
        let spacing: CGFloat = 0.15 // in unit points
        let stripeWidth = (1 - CGFloat(stripeCount - 1) * spacing) / CGFloat(stripeCount)

        var path = Path()
        // First stripe is special
        path.move(to: rect.topLeading)
        path.addLine(to: rect.unitPoint(.init(x: stripeWidth, y: 0)))
        path.addLine(to: rect.unitPoint(.init(x: 0, y: stripeWidth)))
        path.closeSubpath()

        for stripe in 1..<stripeCount {
            let start = CGFloat(stripe) * (stripeWidth + spacing)
            let end = start + stripeWidth
            path.move(to: rect.unitPoint(.init(x: start, y: 0)))
            path.addLine(to: rect.unitPoint(.init(x: end, y: 0)))
            path.addLine(to: rect.unitPoint(.init(x: 0, y: end)))
            path.addLine(to: rect.unitPoint(.init(x: 0, y: start)))
            path.closeSubpath()
        }

        return path
    }
}

extension View {
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func draggable(
        isDragging: Binding<Bool>? = nil,
        offset: Binding<CGSize>,
        coordinateSpace: CoordinateSpace
    ) -> some View {
        modifier(Draggable(
            isDragging: isDragging,
            offset: offset,
            coordinateSpace: coordinateSpace
        ))
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func draggable(
        isDragging: Binding<Bool>? = nil,
        point pointBinding: Binding<CGPoint>,
        coordinateSpace: CoordinateSpace
    ) -> some View {
        let sizeBinding = pointBinding.transform(
            getter: { pt -> CGSize in CGSize(width: pt.x, height: pt.y) },
            setter: { pt, newValue, _ in
                pt = CGPoint(x: newValue.width, y: newValue.height)
            }
        )
        return draggable(
            isDragging: isDragging,
            offset: sizeBinding,
            coordinateSpace: coordinateSpace
        )
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct Draggable: ViewModifier {
    var isDragging: Binding<Bool>?
    @Binding var offset: CGSize
    var coordinateSpace: CoordinateSpace

    @State private var lastTranslation: CGSize? = nil

    func body(content: Content) -> some View {
        content
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: coordinateSpace)
            .onChanged { gv in
                isDragging?.wrappedValue = true
                if let last = lastTranslation {
                    let delta = gv.translation - last
                    offset = offset + delta
                    lastTranslation = gv.translation
                } else {
                    lastTranslation = gv.translation
                }
            }
            .onEnded { gv in
                lastTranslation = nil
                isDragging?.wrappedValue = false
            }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct ResizableAndDraggable_Previews: PreviewProvider {
    static var previews: some View {
        WithState(CGRect(x: 20, y: 20, width: 300, height: 300)) { $frame in
            Color.clear
                .overlay {
                    Text("This view is resizable and draggable")
                        .padding(20)
                        .multilineTextAlignment(.center)
                }
                .resizableAndDraggable(frame: $frame, coordinateSpace: .named("coordSpace"))
                .background {
                    Rectangle()
                        .fill(.ultraThickMaterial)
                        .shadow(radius: 5)
                }
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: frame.minY)
                .coordinateSpace(name: "coordSpace")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
