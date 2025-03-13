import SwiftUI
import CoreData
import UIKit


/// PhotoReviewView: for captured images with options for cropping, transcribing, and saving
/// Provides navigation to transcription view and image editing capabilities
struct PhotoReviewView: View {
    var capturedImage: CGImage      // The image captured by camera to be displayed
    var onSave: () -> Void          // Callback executed when image is saved
    var onBack: () -> Void          // Callback executed when returning to camera
       
    
    @State private var navigateToContentView = false
    @State private var isTranscribing = false
    @State private var isCropping = false
    @State private var croppedImage: UIImage?
    
    @Environment(\.managedObjectContext) private var viewContext  // CoreData context for saving images
    
    var body: some View {
        // Main navigation container
        NavigationView {
            ZStack {
                // Display cropped image if available, otherwise show original captured image
                if let croppedImage = croppedImage, let cgImage = croppedImage.cgImage {
                    Image(cgImage, scale: 1.0, orientation: .right, label: Text("Cropped Photo"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.all)
                } else {
                    Image(capturedImage, scale: 1.0, orientation: .right, label: Text("Captured Photo"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.all)
                }
                
                // Bottom action buttons container
                VStack {
                    Spacer()
                    
                    // Row of action buttons for image manipulation and navigation
                    HStack(spacing: 15) {
                        Spacer()
                        
                        // Button: Returns to camera view discarding current image
                        FloatingActionButton(icon: "arrow.uturn.backward", label: "Retake", color: .black.opacity(0.7)) {
                            onBack()
                        }
                        
                        Spacer()
                        
                        // Button: Opens image cropping interface
                        FloatingActionButton(icon: "crop", label: "Crop", color: .black.opacity(0.7)) {
                            showImageCropper()
                        }
                        
                        Spacer()
                        
                        // Button: Initiates OCR text recognition process
                        FloatingActionButton(icon: "text.bubble", label: "Transcribe", color: .black.opacity(0.7)) {
                            isTranscribing = true
                            // Short delay to show processing indicator before navigation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                navigateToContentView = true
                                isTranscribing = false
                            }
                        }
                        
                        Spacer()
                        
                        
                        // Button: Saves image to CoreData storage
                        FloatingActionButton(icon: "square.and.arrow.down", label: "Save", color: .black.opacity(0.7)) {
                            savePhoto()
                            onSave()
                        }
                        
                        Spacer()
                    }
                }
                
                
                // Loading overlay during transcription processing
                if isTranscribing {
                    VStack {
                        ProgressView("Preparing transcription...") // Loading indicator with status message
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3)) // Semi-transparent background overlay
                    .zIndex(300) // Position above other UI elements
                }
                
                
                // Hidden navigation link to ContentView for transcription
                NavigationLink(
                    destination: ContentView(
                        inputImage: croppedImage ?? UIImage(cgImage: capturedImage), // Use cropped image if available, otherwise original
                        autoTranscribe: true  // Automatically start transcription process
                    ),
                    isActive: $navigateToContentView
                ) {
                    EmptyView() // Empty view since this is programmatically triggered
                }
            }
            .navigationViewStyle(.stack)  // Use stack navigation style
            .toolbar(.hidden, for: .tabBar) // Hide tab bar during review
            .navigationBarBackButtonHidden(true) // Custom back handling
            .sheet(isPresented: $isCropping) { // Cropper presented in sheet style
                ImageCropperView(
                    image: UIImage(cgImage: capturedImage),  // Present cropper with original image
                    onCrop: { croppedImg in
                        croppedImage = croppedImg
                    }
                )
            }
        }
    }
    
    
    // function to set the var for isCropping
    private func showImageCropper() {
        isCropping = true
    }
    
    private func savePhoto() {
        // Use cropped image if available, otherwise use original
        let imageToSave = croppedImage?.cgImage ?? capturedImage
        
        // Convert CGImage to Data for storage
        let uiImage = UIImage(cgImage: imageToSave)
        guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
            print("Could not convert image to data")
            return
        }
        
        // Create and configure new ImageData entity
        let newPhoto = ImageData(context: viewContext)
        newPhoto.id = UUID()
        newPhoto.imageData = imageData
        newPhoto.createdAt = Date()
        
        // Save to CoreData and refresh context
        do {
            try viewContext.save()
            print("Photo saved successfully")
            viewContext.refreshAllObjects()
        } catch {
            print("Error saving: \(error)")
        }
    }
}


/// ImageCropperView: SwiftUI wrapper for the custom image cropping controller
/// Handles data passing between SwiftUI and UIKit
struct ImageCropperView: UIViewControllerRepresentable {
    let image: UIImage
    let onCrop: (UIImage) -> Void // Callback with cropped image result
    @Environment(\.presentationMode) var presentationMode // For dismissing the sheet
    
    
    // Creates the UIKit cropping controller with proper configuration
    func makeUIViewController(context: Context) -> UIImageCropperViewController {
        let controller = UIImageCropperViewController()
        controller.sourceImage = image // Pass source image to controller
        controller.delegate = context.coordinator // Set up communication channel
        return controller
    }
    
    // No implementation needed since view doesn't change after creation
    func updateUIViewController(_ uiViewController: UIImageCropperViewController, context: Context) {}
    
    
    // Creates coordinator to handle delegate callbacks from UIKit
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    
    /// Inneer class to handle communication between UIKit cropper and SwiftUI view
    class Coordinator: NSObject, UIImageCropperViewControllerDelegate {
        let parent: ImageCropperView
        
        init(parent: ImageCropperView) {
            self.parent = parent
        }
        
        // Called when user cancels cropping operation
        func imageCropperDidCancel(_ cropper: UIImageCropperViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // Called when user completes cropping operation
        func imageCropper(_ cropper: UIImageCropperViewController, didFinishCroppingImage croppedImage: UIImage) {
            parent.onCrop(croppedImage)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


// Custom image cropper controller that handles image cropping operations
class UIImageCropperViewController: UIViewController {
    var sourceImage: UIImage!
    var delegate: UIImageCropperViewControllerDelegate?   // Delegate to handle crop events
    
    private var imageView: UIImageView! // Displays the image being cropped
    private var cropOverlayView: UIView!  // Visual indicator of crop area
    private var cropRect: CGRect = .zero // Current crop rectangle dimensions
    
    // Initialize view components and setup UI elements
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupImageView()
        setupCropOverlay()
        setupButtons()
    }
    
    
    // Sets up the image display with proper orientation and constraints
    private func setupImageView() {
        let imageWithOrientation = UIImage(cgImage: sourceImage.cgImage!, scale: sourceImage.scale, orientation: .right)
        imageView = UIImageView(image: imageWithOrientation)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Center image view and make it fill the view
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
    
    // Creates and configures the crop boundary overlay with gestures
    private func setupCropOverlay() {
        cropOverlayView = UIView()
        cropOverlayView.layer.borderWidth = 2
        cropOverlayView.layer.borderColor = UIColor.white.cgColor
        cropOverlayView.backgroundColor = .clear
        cropOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cropOverlayView)
        
        // Add pan gesture to allow moving the crop rect
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cropOverlayView.addGestureRecognizer(panGesture)
        
        // Add pinch gesture to resize the crop rect
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    // Initializes the crop rectangle after view layout is complete
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Set initial crop rect to a reasonable square in the center
        if cropRect == .zero {
            let imageFrame = imageView.frame
            let size = min(imageFrame.width, imageFrame.height) * 0.8
            
            cropRect = CGRect(
                x: imageFrame.midX - size/2,
                y: imageFrame.midY - size/2,
                width: size,
                height: size
            )
            
            cropOverlayView.frame = cropRect
        }
    }
    
    // Handles pan gestures to move the crop rectangle
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        // Update crop rect position
        cropRect.origin.x += translation.x
        cropRect.origin.y += translation.y
        
        // Ensure crop rect stays within image bounds
        let imageFrame = imageView.frame
        cropRect.origin.x = max(imageFrame.minX, min(cropRect.origin.x, imageFrame.maxX - cropRect.width))
        cropRect.origin.y = max(imageFrame.minY, min(cropRect.origin.y, imageFrame.maxY - cropRect.height))
        
        // Update view
        cropOverlayView.frame = cropRect
        
        // Reset translation for continuous movement
        gesture.setTranslation(.zero, in: view)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            // Calculate new size
            let scale = gesture.scale
            let newWidth = cropRect.width * scale
            let newHeight = cropRect.height * scale
            
            let newSize = min(newWidth, newHeight)
            
            // Get current center point
            let centerX = cropRect.midX
            let centerY = cropRect.midY
            
            // Update crop rect maintaining center point
            cropRect = CGRect(
                x: centerX - newSize/2,
                y: centerY - newSize/2,
                width: newSize,
                height: newSize
            )
            
            // Ensure crop rect stays within image bounds
            let imageFrame = imageView.frame
            cropRect.origin.x = max(imageFrame.minX, min(cropRect.origin.x, imageFrame.maxX - cropRect.width))
            cropRect.origin.y = max(imageFrame.minY, min(cropRect.origin.y, imageFrame.maxY - cropRect.height))
            
            // Update view
            cropOverlayView.frame = cropRect
            
            // Reset scale for continuous resizing
            gesture.scale = 1.0
        }
    }
    
    // Creates action buttons for crop operations
    private func setupButtons() {
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        // Position buttons at bottom of screen with padding
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.systemRed
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Crop button
        let cropButton = UIButton(type: .system)
        cropButton.setTitle("Crop", for: .normal)
        cropButton.setTitleColor(.white, for: .normal)
        cropButton.backgroundColor = UIColor.systemBlue
        cropButton.layer.cornerRadius = 8
        cropButton.addTarget(self, action: #selector(cropTapped), for: .touchUpInside)
        
        // Add buttons to the stack
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(cropButton)
    }
    
    // Notifies delegate when user cancels the crop operation
    @objc func cancelTapped() {
        delegate?.imageCropperDidCancel(self)
    }
    
    @objc func cropTapped() {
        // Convert crop rect from view coordinates to image coordinates
        let croppedImage = cropImage()
        // Ensure we maintain the original image orientation
        let correctedImage = UIImage(cgImage: croppedImage.cgImage!, scale: croppedImage.scale, orientation: .right)
        delegate?.imageCropper(self, didFinishCroppingImage: correctedImage)
    }
    
    private func cropImage() -> UIImage {
        // Calculate the scaling factor between the image view and the actual image
        let viewSize = imageView.bounds.size
        let imageSize = sourceImage.size
        
        // Calculate image aspect ratios
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height
        
        var visibleImageFrame: CGRect
        
        if imageAspect > viewAspect {
            // Image is wider than view
            let scale = viewSize.width / imageSize.width
            let scaledHeight = imageSize.height * scale
            let yOffset = (viewSize.height - scaledHeight) / 2
            visibleImageFrame = CGRect(x: 0, y: yOffset, width: viewSize.width, height: scaledHeight)
        } else {
            // Image is taller than view
            let scale = viewSize.height / imageSize.height
            let scaledWidth = imageSize.width * scale
            let xOffset = (viewSize.width - scaledWidth) / 2
            visibleImageFrame = CGRect(x: xOffset, y: 0, width: scaledWidth, height: viewSize.height)
        }
        
        // Convert crop overlay frame to image view coordinates
        let overlayFrameInView = view.convert(cropRect, to: imageView)
        
        // Calculate crop rect in the original image coordinates
        let xScale = imageSize.width / visibleImageFrame.width
        let yScale = imageSize.height / visibleImageFrame.height
        
        let cropX = (overlayFrameInView.origin.x - visibleImageFrame.origin.x) * xScale
        let cropY = (overlayFrameInView.origin.y - visibleImageFrame.origin.y) * yScale
        let cropWidth = overlayFrameInView.width * xScale
        let cropHeight = overlayFrameInView.height * yScale
        
        // Ensure crop values are valid (within image bounds)
        let normalizedX = max(0, min(cropX, imageSize.width))
        let normalizedY = max(0, min(cropY, imageSize.height))
        let normalizedWidth = min(imageSize.width - normalizedX, cropWidth)
        let normalizedHeight = min(imageSize.height - normalizedY, cropHeight)
        
        // Create crop rect in image coordinates
        let cropRectInImage = CGRect(
            x: normalizedX,
            y: normalizedY,
            width: normalizedWidth,
            height: normalizedHeight
        )
        
        // Perform the crop
        if let cgImage = sourceImage.cgImage?.cropping(to: cropRectInImage) {
            return UIImage(cgImage: cgImage, scale: sourceImage.scale, orientation: .right)
        }
        
        // Return original if cropping fails
        return sourceImage
    }
}

// Protocol for the image cropper
protocol UIImageCropperViewControllerDelegate: AnyObject {
    func imageCropperDidCancel(_ cropper: UIImageCropperViewController)
    func imageCropper(_ cropper: UIImageCropperViewController, didFinishCroppingImage croppedImage: UIImage)
}
