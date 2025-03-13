
import SwiftUI
import CoreData
import PhotosUI

struct GalleryView: View, PhotoDeletable {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ImageData.createdAt, ascending: false)],
        animation: .default)
    private var photos: FetchedResults<ImageData>
    
    @State private var selectedPhoto: ImageData?
    @State private var showPhotoDetail = false
    @State private var showDeleteConfirmation = false
    @State private var photoToDelete: ImageData?
    
    @State private var selectedImageCG: CGImage?
    @State private var showingPhotoReview = false
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoFromLibrary = false
    @State private var libraryImageCG: CGImage?
    
    var switchToGalleryTab: () -> Void
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ZStack {
            if showingPhotoReview, let cgImage = selectedImageCG ?? libraryImageCG {
                PhotoReviewView(
                    capturedImage: cgImage,
                    onSave: {
                        showingPhotoReview = false
                        libraryImageCG = nil
                    },
                    onBack: {
                        showingPhotoReview = false
                        libraryImageCG = nil
                    }
                )
                .ignoresSafeArea()
                .zIndex(10)
            } else {
            
            VStack {
                HStack {
                    Text("Photo Gallery")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    
                    Button {
                        // Open photo picker
                        showingPhotoFromLibrary = true
                        
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .photosPicker(isPresented: $showingPhotoFromLibrary, selection: $selectedPhotoItem)
                    .onChange(of: selectedPhotoItem) { newValue in
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
                
                ScrollView {
                    if photos.isEmpty {
                        Text("No photos saved yet")
                            .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(photos, id: \.id) { photo in
                                if let imageData = photo.imageData, let uiImage = UIImage(data: imageData) {
                                    
                                    if let cgImage = uiImage.cgImage {
                                        Image(cgImage, scale: 1.0, orientation: .right, label: Text("Photo"))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .clipped()
                                            .contextMenu {
                                                Button(action: {
                                                    selectedPhoto = photo
                                                    showPhotoDetail = true
                                                }) {
                                                    Label("View", systemImage: "eye")
                                                }
                                                
                                                Button(role: .destructive, action: {
                                                    photoToDelete = photo
                                                    showDeleteConfirmation = true
                                                }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            .onTapGesture {
                                                if let imageData = photo.imageData,
                                                   let uiImage = UIImage(data: imageData),
                                                   let cgImage = uiImage.cgImage {
                                                    selectedImageCG = cgImage
                                                    showingPhotoReview = true
                                                }
                                            }
                                    }
                                } else {
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
                .alert("Delete Photo", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {
                        photoToDelete = nil
                    }
                    Button("Delete", role: .destructive) {
                        if let photo = photoToDelete {
                            deletePhoto(photo, from: viewContext)
                            // If we were viewing this photo, go back
                            if showPhotoDetail && selectedPhoto?.id == photo.id {
                                showPhotoDetail = false
                            }
                        }
                        photoToDelete = nil
                    }
                } message: {
                    Text("Are you sure you want to delete this photo? This action cannot be undone.")
                }
                
                
                
            }
        }
        }
    }
}
