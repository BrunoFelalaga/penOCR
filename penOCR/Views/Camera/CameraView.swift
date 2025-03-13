import SwiftUI
import CoreData

struct CameraView: View {
    @StateObject private var frameModel = FrameHandler()
    @Binding var selectedTab: Int
    @State private var showPhotoReview = false

    // Update initializer for previews
    init(selectedTab: Binding<Int> = .constant(1)) {
        self._selectedTab = selectedTab
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            #if targetEnvironment(simulator)
                // Use black background for simulator
                Color.black.ignoresSafeArea()
            #else
                // Use camera feed on actual device
            if showPhotoReview && frameModel.capturedImage != nil {
                    
                    PhotoReviewView( // Use the new PhotoReviewView instead
                        capturedImage: frameModel.capturedImage!,
                        onSave: {
                            resetCameraState()
                            DispatchQueue.main.async { self.selectedTab = 0 } },
                        onBack: { resetCameraState() }
                    )
                    .edgesIgnoringSafeArea(.all)
                    .toolbar(.hidden, for: .tabBar)
            } else {
                FrameView(image: frameModel.frame, onZoomChanged: { newZoom in
                    frameModel.setZoom(factor: newZoom)
                }, onFocusTap: { point, size in
                    frameModel.setFocus(at: point, viewSize: size)
                })
                .edgesIgnoringSafeArea(.all)
                            }
            #endif
            
            
            if !showPhotoReview {
               VStack {
                   
                   // Top controls
                   HStack {
                       // Brightness control
                       HStack(spacing: 5) {
                           Image(systemName: "sun.max.fill")
                               .font(.system(size: 16))
                               .foregroundColor(.white)
                           
                           Slider(value: $frameModel.brightnessValue, in: 0...1)
                               .frame(width: 80)
                               .accentColor(.white)
                               .onChange(of: frameModel.brightnessValue) { newValue in
                                   frameModel.setBrightness(newValue)
                               }
                               .controlSize(.mini)  // Makes the slider smaller overall
                       }
                       .padding(.vertical, 6)
                       .padding(.horizontal, 10)
                       .background(Color.black.opacity(0.6))
                       .cornerRadius(20)
                       
                       Spacer()
                       
                       // Flash control
                       Button(action: {
                           frameModel.toggleTorch()
                       }) {
                           Image(systemName: frameModel.torchActive ? "bolt.fill" : "bolt.slash")
                               .font(.system(size: 18))
                               .foregroundColor(frameModel.torchActive ? .yellow : .white)
                               .padding(12)
                               .background(Color.black.opacity(0.6))
                               .clipShape(Circle())
                       }
                   }
                   .padding(.horizontal, 20)
                   .padding(.top, 50)
                   
                   Spacer()
                   
                   Button(action: {
                       #if targetEnvironment(simulator)
                       showPhotoReview = true
                       #else
                       frameModel.capturePhoto()
                       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                           if frameModel.capturedImage != nil {
                               showPhotoReview = true
                           }
                       }
                       #endif
                   }){
                       ZStack {
                           Circle()
                               .fill(Color.white.opacity(0.2))
                               .frame(width: 80, height: 80)
                           
                           Circle()
                               .strokeBorder(Color.white, lineWidth: 4)
                               .frame(width: 70, height: 70)
                           
                           Circle()
                               .fill(Color.white)
                               .frame(width: 60, height: 60)
                       }
                   }
                   .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 0)
                   .padding(.bottom, 50)
               }
               .frame(maxWidth: .infinity, maxHeight: .infinity)
               .background(Color.clear)
               .zIndex(100)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    func resetCameraState() {
        self.showPhotoReview = false
        self.frameModel.capturedImage = nil
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
