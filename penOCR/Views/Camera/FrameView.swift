import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private var label = Text("Frame")
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    var onZoomChanged: ((CGFloat) -> Void)?
    var onFocusTap: ((CGPoint, CGSize) -> Void)?
    
    init(image: CGImage? = nil, onZoomChanged: ((CGFloat) -> Void)? = nil, onFocusTap: ((CGPoint, CGSize) -> Void)? = nil) {
        self.image = image
        self.onZoomChanged = onZoomChanged
        self.onFocusTap = onFocusTap
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1.0), 5.0)
                                onZoomChanged?(scale)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        onFocusTap?(location, geometry.size)
                   
                    }
            } else {
                Color.black
                    .allowsHitTesting(false)
            }
        }
    }
}
