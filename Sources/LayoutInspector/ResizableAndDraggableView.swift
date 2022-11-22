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
                    Rectangle()
                        .frame(height: Self.titleBarHeight)
                        .foregroundStyle(.tertiary)
                        .draggable(point: $frame.origin, coordinateSpace: coordinateSpace)

                    let resizeHandle = ResizeHandle()
                        .fill(.secondary)
                        .frame(width: 20, height: 20)
                    resizeHandle
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .draggable(point: $frame.topLeading, coordinateSpace: coordinateSpace)
                    resizeHandle
                        .rotationEffect(.degrees(90))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .draggable(point: $frame.topTrailing, coordinateSpace: coordinateSpace)
                    resizeHandle
                        .rotationEffect(.degrees(-90))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .draggable(point: $frame.bottomLeading, coordinateSpace: coordinateSpace)
                    resizeHandle
                        .rotationEffect(.degrees(180))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .draggable(point: $frame.bottomTrailing, coordinateSpace: coordinateSpace)
                }
            }
    }
}

struct ResizeHandle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: rect.topLeading)
        path.addLine(to: rect.topTrailing)
        path.addLine(to: rect.bottomLeading)
        path.closeSubpath()
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
