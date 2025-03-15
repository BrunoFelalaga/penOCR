//
//  TranscriptionDetailView.swift
//  penOCR2
//
//  Created by Bruno Felalaga  on 3/12/25.
//


import SwiftUI
import PhotosUI
import QuickLook
import UniformTypeIdentifiers


/// TranscriptionDetailView: Detailed view for viewing and editing saved transcriptions with attachment support
/// Provides editing, speech synthesis, and export capabilities
struct TranscriptionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var transcription: Transcription
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedText: String
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
    // File picker states for attachment functionality
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedDocumentURL: URL?
    
    
    // Initialize view with transcription data and prepare editable copies
    init(transcription: Transcription) {
        self.transcription = transcription
        self._editedTitle = State(initialValue: transcription.title ?? "")
        self._editedText = State(initialValue: transcription.text ?? "")
    }


    // Simplified Main view body combining content sections and handling navigation/toolbar
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                transcriptionContentView // Main transcription display and editing area
                attachmentsView // List of attached files and documents
            }
            .padding()
        }
        .navigationTitle(isEditing ? "Editing Transcription" : "Transcription Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent } // Custom toolbar with action buttons
        .photosPicker(isPresented: $showImagePicker, selection: $selectedImageItem, matching: .images)
        .onChange(of: selectedImageItem) { newValue in
            handleImageSelection(newValue) // Process selected image for attachment
        }

        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.data, UTType.content, UTType.image],
            allowsMultipleSelection: false
        )
        { result in
            handleFileImport(result) // Process imported file for attachment
        }
    }

    // Main transcription content section handling both display and edit modes
    private var transcriptionContentView: some View {
        VStack(alignment: .leading) {
            if isEditing {
                
                // Edit mode - editable title field
                TextField("Title", text: $editedTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Multi-line text editor for content
                TextEditor(text: $editedText)
                    .frame(minHeight: 200)
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                
                // View mode - display title with fallback
                Text(transcription.title ?? "Untitled")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Display transcription content
                Text(transcription.text ?? "")
                    .padding(.horizontal)
            }
            
            // Creation timestamp display
            Text("Created: \(transcription.createdAt ?? Date(), format: .dateTime)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }

    // Horizontal scrolling list of attachments with preview and context menu actions
    private var attachmentsView: some View {
        Group {
            if !transcription.attachmentArray.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Attachments") // Section header
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Horizontal scrollable attachment previews
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(transcription.attachmentArray) { attachment in
                                AttachmentThumbnailView(attachment: attachment)
                                    .frame(width: 100, height: 100)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .contextMenu {
                                        
                                        // Delete option with destructive styling
                                        Button(role: .destructive) {
                                            deleteAttachment(attachment)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        // Share option for external export
                                        Button {
                                            print("share pressed in transcription detail view")
                                            shareAttachment(attachment)
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // Custom toolbar with context-aware editing, sharing, and attachment functions
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            // Toggle between Edit and Save based on editing state
            if isEditing {
                Button("Save") { // Save button
                    print("save pressed in transcription detail view")
                    saveChanges()
                    isEditing = false
                }
            } else {
                Button("Edit") { // Edit button
                    print("edit pressed in transcription detail view")
                    isEditing = true
                }
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            
            // Sharing button for external export
            Button {
                print("share transcription pressed in transcription detail view")
                shareTranscription()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            
            // Text-to-speech toggle with dynamic icon
            Button {
                print("toggle speech pressed in transcription detail view")
                speechSynthesizer.toggleSpeech(text: transcription.text ?? "")
            } label: {
                
                Image(systemName: speechSynthesizer.isSpeaking ? "speaker.slash" : "speaker.wave.2")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            
            // Attachment menu with options for different content types
            Menu {
                Button {
                    print("image picker pressed in transcription detail view")
                    showImagePicker = true
                } label: {
                    Label("Add Image", systemImage: "photo")
                }
                
                Button {
                    print("file picker pressed in transcription detail view")
                    showFilePicker = true
                } label: {
                    Label("Add Document", systemImage: "doc")
                }
            } label: {
                Image(systemName: "paperclip")
            }
        }
    }

    // Process selected image from photo picker and add as attachment
    private func handleImageSelection(_ newValue: PhotosPickerItem?) {
        
        // Create asynchronous task to handle image loading without blocking the UI thread
        Task {
            if let photoItem = newValue,
               let data = try? await photoItem.loadTransferable(type: Data.self) { // Extract image data from picker result
                await MainActor.run {
                    addImageAttachment(data: data) // Create and save attachment on main thread
                    selectedImageItem = nil  // Reset selection state
                }
            }
        }
    }

    // Process file import from system file picker
    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            let selectedFile = try result.get().first
            if let selectedFile = selectedFile {
                
                // Request temporary access to security-scoped resource
                if selectedFile.startAccessingSecurityScopedResource() {
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    // Extract file data and metadata
                    let data = try Data(contentsOf: selectedFile)
                    let fileName = selectedFile.lastPathComponent
                    let fileType = selectedFile.pathExtension
                    
                    // Attach file with metadata and daya
                    addDocumentAttachment(data: data, fileName: fileName, fileType: fileType)
                }
            }
        } catch {
            print("File import error: \(error)")
        }
    }
    
    
    // Save edited transcription data to persistent storage
    private func saveChanges() {
        transcription.title = editedTitle // Update title with edited value
        transcription.text = editedText // Update text content with edited value
        
        do {
            try viewContext.save() // Commit changes to Core Data
        } catch {
            print("Error saving changes: \(error)")
        }
    }
    
    
    // Shares the transcription via system share sheet
    private func shareTranscription() {
        // Format text with title and content for sharing
        let text = """
        \(transcription.title ?? "Untitled")
        
        \(transcription.text ?? "")
        """
        
        // Create activity view controller with formatted text
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        
        // Present share sheet from the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    
    // Creates and saves an image attachment to the transcription
    private func addImageAttachment(data: Data) {
        
        // Create new Attachment entity and set properties
        let attachment = Attachment(context: viewContext)
        attachment.id = UUID()
        attachment.data = data
        attachment.type = "image"
        attachment.fileName = "Image \(Date().formatted(.dateTime))"
        attachment.createdAt = Date()
        attachment.transcription = transcription
        
        do {
            try viewContext.save() // Save changes to Core Data context
        } catch {
            print("Error saving image attachment: \(error)")
        }
    }
    
    
    // Creates and saves a document attachment to the transcription
    private func addDocumentAttachment(data: Data, fileName: String, fileType: String) {
        
        // Create new Attachment entity and set properties
        let attachment = Attachment(context: viewContext)
        attachment.id = UUID()
        attachment.data = data
        attachment.type = "document-\(fileType)"
        attachment.fileName = fileName
        attachment.createdAt = Date()
        attachment.transcription = transcription
        
        do {
            try viewContext.save() // Save changes to Core Data context
        } catch {
            print("Error saving document attachment: \(error)")
        }
    }
    
    
    // Removes an attachment from the transcription and deletes from Core Data
    private func deleteAttachment(_ attachment: Attachment) {
        viewContext.delete(attachment)
        
        do {
            try viewContext.save()  // Save changes to Core Data context
        } catch {
            print("Error deleting attachment: \(error)")
        }
    }
    
    
    // Shares an attachment via system share sheet
    private func shareAttachment(_ attachment: Attachment) {
        guard let data = attachment.data else { return }
        
        
        // Create activity view controller with attachment data
        let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        
        
        // Present share sheet from the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// Attachment detail view
/// Displays attachment contents in full screen with dismissal option
struct AttachmentDetailView: View {
    let attachment: Attachment
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            
            // Display image if attachment is an image with valid data
            if attachment.type == "image", let data = attachment.data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            } else {
                // Fallback message if preview not available
                Text("File preview not available")
                    .foregroundColor(.secondary)
            }
            
            // Close button to dismiss the view
            Button("Close") {
                dismiss()
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom, 20)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}



///  AttachmentThumbnailView: Displays an attachment thumbnail with preview functionality
/// Shows image or document icon based on attachment type
struct AttachmentThumbnailView: View {
    let attachment: Attachment
    @State private var showingPreview = false
    
    var body: some View {
        VStack {
            
            // Display thumbnail based on attachment type
            if attachment.type == "image", let data = attachment.data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .clipped()
            } else {
                Image(systemName: "doc.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
            }
            
            
            // Show file name below thumbnail with truncation
            Text(attachment.fileName ?? "File")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .onTapGesture {
            if let data = attachment.data {
                // Prepare file for QuickLook preview by creating temporary file
                let safeFileName = (attachment.fileName ?? "file")
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: ":", with: "-")
                
                
                // Add .jpg extension for image files if needed
                let fileNameWithExt = attachment.type == "image" && !safeFileName.contains(".")
                                    ? safeFileName + ".jpg"
                                    : safeFileName
                
                // Save file to temporary directory for QuickLook preview
                let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                let fileURL = temporaryDirectoryURL.appendingPathComponent(fileNameWithExt)
                
                // Write data to temporary file and trigger preview
                do {
                    try data.write(to: fileURL)
                    showingPreview = true
                } catch {
                    print("Error preparing file for preview: \(error)")
                }
            }
        }

        .sheet(isPresented: $showingPreview) {
            VStack {
                
                // Close button at top right
                HStack {
                    Spacer()
                    FloatingActionButton(
                        icon: "xmark.circle",
                        label: "",
                        color: .black.opacity(0.1)
                    ) {
                        showingPreview = false
                    }
                    .padding()
                }
                
                // Display file preview using QuickLook if file exists
                if let fileName = attachment.fileName {
                    
                    // Sanitize filename by removing problematic characters
                    let safeFileName = fileName.replacingOccurrences(of: "/", with: "-")
                                             .replacingOccurrences(of: ":", with: "-")
                    
                    // Add jpg extension for images if needed
                    let fileNameWithExt = attachment.type == "image" && !safeFileName.contains(".")
                                        ? safeFileName + ".jpg"
                                        : safeFileName
                    
                    // Create file URL in temporary directory
                    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileNameWithExt)
                    
                    // Display file preview if it exists
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        QuickLookPreview(url: fileURL)
                    }
                }
            }
        }
    }
}



/// QuickLook Preview: QuickLook Preview controller wrapper
/// Enables iOS document preview functionality within SwiftUI
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    // Creates and configures the QuickLook preview controller
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    
    // Creates the coordinator to handle data source functionality
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    // Coordinator: implements the QLPreviewControllerDataSource protocol
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookPreview // Store reference to parent QuickLookPreview
        
        // Initialize with parent to access URL property
        init(_ parent: QuickLookPreview) {
            self.parent = parent
        }
        
        
        // Returns number of items to preview (always 1 in this case)
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        // Returns the URL as the preview item
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as NSURL
        }
    }
}




/// Extension to provide sorted attachments array from Set relationship
extension Transcription {
    @objc var attachmentArray: [Attachment] {
        // Convert optional Set to array and sort by creation date (newest first)
        let set = attachments as? Set<Attachment> ?? []
        return set.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
    }
}

