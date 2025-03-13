import AVFoundation
import CoreImage


// Camera feed handler: manages device camera, image processing and user interactions
// Handles permissions, camera setup, image capture and camera controls
class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage? // Current processed camera frame
    private var permissionGranted = false
    private let captureSession = AVCaptureSession() // Core camera session
    private let sessionQueue = DispatchQueue(label: "sessionQueue") // Background queue for camera operations
    private let context = CIContext() // Context for image processing
    @Published var brightnessValue: Double = 0.5
    @Published var torchActive: Bool = false
    
    private let photoOutput = AVCapturePhotoOutput() // Handler for photo capture
    @Published var capturedImage: CGImage?
    @Published var zoomFactor: CGFloat = 1.0
    private var videoDevice: AVCaptureDevice? // Reference to the physical camera
    
    
    
    // Initialize the camera handler and start capture session
    override init() {
        super.init()
        checkPermission()
        
        // Run camera setup on background thread to avoid blocking main UI
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    // Check if camera permission is already granted
    func checkPermission() {
        // Check camera permission status and set peremissionGranted accordingly
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                permissionGranted = true
            case .notDetermined:
                requestPermission()
            default:
                permissionGranted = false
        }
    }
    
    // Request camera permission from user and setup camera if granted
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            
            // Initialize camera session if permission granted
            if granted {
                self.sessionQueue.async { [unowned self] in
                    self.setupCaptureSession()
                    self.captureSession.startRunning()
                }
            }
        }
    }
    
    
    // Configure and initialize the camera capture pipeline
    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        
        // Exit if camera permission is not granted
        guard permissionGranted else {
            print("Permission not granted")
            return
        }
        
        // Try to get the default back camera, fallback to any available camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
              ?? AVCaptureDevice.default(for: .video) else {
            print("No camera available")
            return
        }
        self.videoDevice = device
        
        
        // Create input from camera device
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: device) else {
            print("Could not create input device")
            return
        }
        
        
        // Add camera input to session if compatible
        guard captureSession.canAddInput(videoDeviceInput) else {
            print("Could not add input to session")
            return
        }
        captureSession.addInput(videoDeviceInput)
        
        
        
        // Add video output to session if compatible
        guard captureSession.canAddOutput(videoOutput) else {
            print("Could not add output to session")
            return
        }
        captureSession.addOutput(videoOutput)
        
        
        
        // Add photo capture output to session if compatible
        guard captureSession.canAddOutput(photoOutput) else {
            print("Could not add photo output to session")
            return
        }
        captureSession.addOutput(photoOutput)
        
        
        
        // Register as delegate to receive camera frames
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        
        // Set video orientation to portrait if supported
        if let connection = videoOutput.connection(with: .video) {
            // Try portrait first
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }
    
    
    // Apply zoom level to camera within acceptable limits
    func setZoom(factor: CGFloat) {
        let zoom = max(1.0, min(factor, 5.0)) // Limit zoom between 1x and 5x
        
        
        // Process zoom on background thread to avoid UI blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let device = self.videoDevice else { return }
            
            do {
                // Lock device for configuration changes
                try device.lockForConfiguration()
                
                // Apply zoom within device capabilities
                let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0)
                let zoomFactor = min(zoom, maxZoom)
                
                device.videoZoomFactor = zoomFactor
                device.unlockForConfiguration()
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.zoomFactor = zoomFactor
                }
            } catch {
                print("Error setting zoom: \(error.localizedDescription)")
            }
        }
    }
    
    
    // Capture a still photo using current camera settings
    func capturePhoto() {
        print("Capturing photo...")
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    
    // Set camera focus and exposure point based on screen tap position
    func setFocus(at point: CGPoint, viewSize: CGSize) {
        guard let device = videoDevice else { return }
        
        // Convert tap coordinates to camera coordinates (0,0 to 1,1)
        let focusPoint = CGPoint(
            x: point.y / viewSize.height,
            y: 1.0 - (point.x / viewSize.width)
        )
        
        do {
            // Lock device for configuration changes
            try device.lockForConfiguration()
            
            // Set focus point if supported by device
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            
            // Set exposure point if supported by device
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }
            
            // UnLock device after configuration changes
            device.unlockForConfiguration()
        } catch {
            print("Error setting focus: \(error.localizedDescription)")
        }
    }


}



// Extension: Processes video frames from camera and converts them to images
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Receives camera output frames and updates the main UI with processed images
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        // Update UI with the latest frame on main thread
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
    }
    
    // Converts a CMSampleBuffer to a CGImage for display
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        // Create intermediate CIImage from buffer
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
    
    
    // Adjusts camera exposure to achieve different brightness levels
    func setBrightness(_ value: Double) {
        guard let device = videoDevice else { return }
        do {
            try device.lockForConfiguration() // Lock device for configuration changes
            
            // Convert 0-1 range to device-specific range
            let targetBias = Float(value * 2 - 1) * device.maxExposureTargetBias
            device.setExposureTargetBias(targetBias)
            
            device.unlockForConfiguration() // unLock device after configuration changes
            brightnessValue = value
        } catch {
            print("Error setting brightness: \(error)")
        }
    }

    // Toggles device flashlight on/off for low-light photography
    func toggleTorch() {
        guard let device = videoDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration() // Lock device for configuration changes
            
            // Switch between on and off states
            if device.torchMode == .off {
                try device.setTorchModeOn(level: 1.0)
                torchActive = true
            } else {
                device.torchMode = .off
                torchActive = false
            }
            
            device.unlockForConfiguration() // unLock device after configuration changes
        } catch {
            print("Error toggling torch: \(error)")
        }
    }
}


// Handles photo capture callbacks for still images
extension FrameHandler: AVCapturePhotoCaptureDelegate {
    
    // Processes captured photo data and updates the UI with the result
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        // Exit early if capture fails with error
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        // Get raw image data from captured photo
        guard let imageData = photo.fileDataRepresentation() else {
            print("Could not get image data")
            return
        }
        
        // Convert raw data to CIImage format
        guard let ciImage = CIImage(data: imageData) else {
            print("Could not create CIImage")
            return
        }
        
        // Convert to CGImage for display compatibility
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Could not create CGImage")
            return
        }
        
        // Update UI with captured image on main thread
        DispatchQueue.main.async { [weak self] in
            print("Photo captured successfully")
            self?.capturedImage = cgImage
        }
    }
}
