import SwiftUI
import CoreData


// Camera interface for capturing images with real-time preview and adjustments
// Provides camera controls and transitions to photo review when image is captured
struct CameraView: View {
    @StateObject private var frameModel = FrameHandler()
    @Binding var selectedTab: Int
    @State private var showPhotoReview = false

    // Initializer with default tab selection for previews
    init(selectedTab: Binding<Int> = .constant(1)) {
        self._selectedTab = selectedTab
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            #if targetEnvironment(simulator)
                // Simulator fallback - display black background instead of camera
                Color.black.ignoresSafeArea()
            #else
            // Display photo review if image captured, otherwise show camera feed
            if showPhotoReview && frameModel.capturedImage != nil {
                    
                    PhotoReviewView( // Photo review screen with captured image
                        capturedImage: frameModel.capturedImage!,
                        onSave: {
                            resetCameraState()
                            DispatchQueue.main.async { self.selectedTab = 0 } }, // Navigate to content tab after saving
                        onBack: { resetCameraState() } // Return to camera view
                    )
                    .edgesIgnoringSafeArea(.all)
                    .toolbar(.hidden, for: .tabBar)
            } else { // Show frameview if no image captured
                FrameView(image: frameModel.frame, onZoomChanged: { newZoom in
                    frameModel.setZoom(factor: newZoom) // Update zoom level in camera
                }, onFocusTap: { point, size in
                    frameModel.setFocus(at: point, viewSize: size) // Set focus point in camera
                })
                .edgesIgnoringSafeArea(.all)
                            }
            #endif
            
            
            // Camera controls overlay
            if !showPhotoReview {
               VStack {
                   
                   // Top row controls for brightness and flash
                   HStack {
                       // Brightness adjustment slider with icon
                       HStack(spacing: 5) {
                           Image(systemName: "sun.max.fill")
                               .font(.system(size: 16))
                               .foregroundColor(.white)
                           
                           // Slider for brightness
                           Slider(value: $frameModel.brightnessValue, in: 0...1)
                               .frame(width: 80)
                               .accentColor(.white)
                               .onChange(of: frameModel.brightnessValue) { newValue in
                                   print("Brightness adjusted to: \(newValue)")
                                   frameModel.setBrightness(newValue)
                               }
                               .controlSize(.mini)  // Makes the slider smaller overall
                       }
                       .padding(.vertical, 6)
                       .padding(.horizontal, 10)
                       .background(Color.black.opacity(0.6))
                       .cornerRadius(20)
                       
                       Spacer()
                       
                       // Flash control button
                       Button(action: {
                           print("Flash toggle pressed: \(frameModel.torchActive ? "off" : "on")")
                           frameModel.toggleTorch() // Toggle camera flash/torch
                       }) { // Flash image
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
                   
                   // Camera capture button
                   Button(action: {
                       print("Capture button pressed, initiating photo capture")
                       
                       #if targetEnvironment(simulator)
                       showPhotoReview = true // Simulate photo capture in simulator
                       #else
                       frameModel.capturePhoto() // Trigger photo capture
                       // Show review screen after capture
                       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                           if frameModel.capturedImage != nil {
                               showPhotoReview = true
                           }
                       }
                       #endif
                   }){
                       ZStack {
                           // Shutter button
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
               .zIndex(100) // Ensure controls stay on top
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // Resets camera to initial state after photo capture
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
