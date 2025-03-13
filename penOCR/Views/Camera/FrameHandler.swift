import AVFoundation
import CoreImage

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    @Published var brightnessValue: Double = 0.5
    @Published var torchActive: Bool = false
    
    private let photoOutput = AVCapturePhotoOutput()
    @Published var capturedImage: CGImage?
    @Published var zoomFactor: CGFloat = 1.0
    private var videoDevice: AVCaptureDevice?
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                permissionGranted = true
            case .notDetermined:
                requestPermission()
            default:
                permissionGranted = false
        }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            
            if granted {
                self.sessionQueue.async { [unowned self] in
                    self.setupCaptureSession()
                    self.captureSession.startRunning()
                }
            }
        }
    }
    
    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        
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
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: device) else {
            print("Could not create input device")
            return
        }
        
        guard captureSession.canAddInput(videoDeviceInput) else {
            print("Could not add input to session")
            return
        }
        
        captureSession.addInput(videoDeviceInput)
        
        guard captureSession.canAddOutput(videoOutput) else {
            print("Could not add output to session")
            return
        }
        
        captureSession.addOutput(videoOutput)
        
        guard captureSession.canAddOutput(photoOutput) else {
            print("Could not add photo output to session")
            return
        }
                
        captureSession.addOutput(photoOutput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        
        if let connection = videoOutput.connection(with: .video) {
            // Try portrait first
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }
    
    func setZoom(factor: CGFloat) {
        let zoom = max(1.0, min(factor, 5.0)) // Limit zoom between 1x and 5x
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let device = self.videoDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                // Check device zoom capabilities
                let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0)
                let zoomFactor = min(zoom, maxZoom)
                
                device.videoZoomFactor = zoomFactor
                device.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.zoomFactor = zoomFactor
                }
            } catch {
                print("Error setting zoom: \(error.localizedDescription)")
            }
        }
    }
    
    func capturePhoto() {
        print("Capturing photo...")
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    
    func setFocus(at point: CGPoint, viewSize: CGSize) {
        guard let device = videoDevice else { return }
        
        // Convert tap coordinates to camera coordinates (0,0 to 1,1)
        let focusPoint = CGPoint(
            x: point.y / viewSize.height,
            y: 1.0 - (point.x / viewSize.width)
        )
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting focus: \(error.localizedDescription)")
        }
    }


}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
    
    func setBrightness(_ value: Double) {
        guard let device = videoDevice else { return }
        do {
            try device.lockForConfiguration()
            
            // Convert 0-1 range to device-specific range
            let targetBias = Float(value * 2 - 1) * device.maxExposureTargetBias
            device.setExposureTargetBias(targetBias)
            
            device.unlockForConfiguration()
            brightnessValue = value
        } catch {
            print("Error setting brightness: \(error)")
        }
    }

    func toggleTorch() {
        guard let device = videoDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            
            if device.torchMode == .off {
                try device.setTorchModeOn(level: 1.0)
                torchActive = true
            } else {
                device.torchMode = .off
                torchActive = false
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error toggling torch: \(error)")
        }
    }
}


extension FrameHandler: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Could not get image data")
            return
        }
        
        guard let ciImage = CIImage(data: imageData) else {
            print("Could not create CIImage")
            return
        }
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Could not create CGImage")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            print("Photo captured successfully")
            self?.capturedImage = cgImage
        }
    }
}
