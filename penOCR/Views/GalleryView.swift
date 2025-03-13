
import SwiftUI
import CoreData
import PhotosUI

/// GalleryView: Displays saved photos in a grid layout with view/delete functionality
/// Implements PhotoDeletable protocol for photo management
struct GalleryView: View, PhotoDeletable {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ImageData.createdAt, ascending: false)],
        animation: .default)
    private var photos: FetchedResults<ImageData> // Sorted photos from CoreData
    
    // State variables for photo selection and manipulation
    @State private var selectedPhoto: ImageData?
    @State private var showPhotoDetail = false
    @State private var showDeleteConfirmation = false
    @State private var photoToDelete: ImageData?
    
    // State variables for photo review functionality
    @State private var selectedImageCG: CGImage?
    @State private var showingPhotoReview = false
    
    // State variables for photo library integration
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoFromLibrary = false
    @State private var libraryImageCG: CGImage?
    
    var switchToGalleryTab: () -> Void
    
    // Grid layout configuration
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    
    var body: some View {
        ZStack {
            
            // Show photo review screen when an image is selected else show the gallery
            if showingPhotoReview, let cgImage = selectedImageCG ?? libraryImageCG {
                PhotoReviewView( // Display PhotoReviewView with callbacks to reset state when finished
                    capturedImage: cgImage,
                    onSave: { // Reset view state after saving
                        showingPhotoReview = false
                        libraryImageCG = nil
                    },
                    onBack: { // Reset view state when canceling
                        showingPhotoReview = false
                        libraryImageCG = nil
                    }
                )
                .ignoresSafeArea()
                .zIndex(10)
            } else {
            
            // Main gallery view
            VStack {
                
                // Header with title and import button
                HStack {
                    Text("Photo Gallery")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    
                    // Photo import button from library
                    Button {
                        showingPhotoFromLibrary = true
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .photosPicker(isPresented: $showingPhotoFromLibrary, selection: $selectedPhotoItem)
                    .onChange(of: selectedPhotoItem) { newValue in
                        // Process selected photo and prepare for review
                        Task {
                            if let photoItem = newValue,
                               let data = try? await photoItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data),
                               let cgImage = uiImage.cgImage {
                                await MainActor.run {
                                    libraryImageCG = cgImage
                                    showingPhotoReview = true
                                }
                            }
                        }
                    }
                    
                }
                
                // Photo grid or empty state message
                ScrollView {
                    if photos.isEmpty {
                        Text("No photos saved yet")
                            .padding()
                    } else {
                        
                        // Grid layout of saved photos
                        LazyVGrid(columns: columns, spacing: 10) {
                            
                            ForEach(photos, id: \.id) { photo in
                                // Display image thumbnail with context menu
                                if let imageData = photo.imageData, let uiImage = UIImage(data: imageData) {
                                    
                                    if let cgImage = uiImage.cgImage {
                                        Image(cgImage, scale: 1.0, orientation: .right, label: Text("Photo"))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .clipped()
                                            .contextMenu {
                                                
                                                // View option in context menu
                                                Button(action: {
                                                    selectedPhoto = photo
                                                    showPhotoDetail = true
                                                }) {
                                                    Label("View", systemImage: "eye")
                                                }
                                                
                                                // Delete option in context menu
                                                Button(role: .destructive, action: {
                                                    photoToDelete = photo
                                                    showDeleteConfirmation = true
                                                }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            // Handle tap to view full image
                                            .onTapGesture {
                                                if let imageData = photo.imageData,
                                                   let uiImage = UIImage(data: imageData),
                                                   let cgImage = uiImage.cgImage {
                                                    selectedImageCG = cgImage
                                                    showingPhotoReview = true
                                                }
                                            }
                                    }
                                } else { // Placeholder for failed image load
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Photo Gallery")
                .toolbar(.visible, for: .tabBar)
                // Confirmation dialog for photo deletion
                .alert("Delete Photo", isPresented: $showDeleteConfirmation) {
                    // Cancel button dismisses dialog without action
                    Button("Cancel", role: .cancel) {
                        photoToDelete = nil
                    }
                    
                    // Delete button removes photo from persistent storage
                    Button("Delete", role: .destructive) {
                        if let photo = photoToDelete {
                            deletePhoto(photo, from: viewContext)
                            
                            // Close detail view if currently viewing the deleted photo
                            if showPhotoDetail && selectedPhoto?.id == photo.id {
                                showPhotoDetail = false
                            }
                        }
                        photoToDelete = nil
                    }
                } message: { // Alert message explaining the permanent nature of deletion
                    Text("Are you sure you want to delete this photo? This action cannot be undone.")
                }
                
                
                
            }
        }
        }
    }
}
