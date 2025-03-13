import SwiftUI


// Frameview: Displays camera preview frames and handles zoom/focus gestures
// Renders captured images with appropriate scaling and user interactions
struct FrameView: View {
    var image: CGImage?
    private var label = Text("Frame")
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    var onZoomChanged: ((CGFloat) -> Void)?
    var onFocusTap: ((CGPoint, CGSize) -> Void)?
    
    
    // Initializes view with optional image and gesture handlers
    init(image: CGImage? = nil, onZoomChanged: ((CGFloat) -> Void)? = nil, onFocusTap: ((CGPoint, CGSize) -> Void)? = nil) {
        self.image = image
        self.onZoomChanged = onZoomChanged
        self.onFocusTap = onFocusTap
    }
    

    var body: some View {
        
        // Use geometry reader to access view dimensions and position
        GeometryReader { geometry in
            
            // Display camera frame with zoom and focus capabilities
            if let image = image {
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .gesture(
                        // Handle pinch gestures for zooming camera
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1.0), 5.0) // Limit zoom between 1x-5x
                                onZoomChanged?(scale)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                    .contentShape(Rectangle())
                    // Enable tap to focus on specific areas of frame
                    .onTapGesture { location in
                        onFocusTap?(location, geometry.size)
                   
                    }
            } else {
                // Display black placeholder when no camera frame is available
                Color.black
                    .allowsHitTesting(false)
            }
        }
    }
}
