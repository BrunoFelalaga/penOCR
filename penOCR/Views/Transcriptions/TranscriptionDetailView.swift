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

struct TranscriptionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var transcription: Transcription
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedText: String
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
    // File picker states
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedDocumentURL: URL?
    
    init(transcription: Transcription) {
        self.transcription = transcription
        self._editedTitle = State(initialValue: transcription.title ?? "")
        self._editedText = State(initialValue: transcription.text ?? "")
    }


    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                transcriptionContentView
                attachmentsView
            }
            .padding()
        }
        .navigationTitle(isEditing ? "Editing Transcription" : "Transcription Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedImageItem, matching: .images)
        .onChange(of: selectedImageItem) { newValue in
            handleImageSelection(newValue)
        }

        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.data, UTType.content, UTType.image],
            allowsMultipleSelection: false
        )
        { result in
            handleFileImport(result)
        }
    }

    private var transcriptionContentView: some View {
        VStack(alignment: .leading) {
            if isEditing {
                TextField("Title", text: $editedTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                TextEditor(text: $editedText)
                    .frame(minHeight: 200)
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text(transcription.title ?? "Untitled")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text(transcription.text ?? "")
                    .padding(.horizontal)
            }
            
            Text("Created: \(transcription.createdAt ?? Date(), format: .dateTime)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }

    private var attachmentsView: some View {
        Group {
            if !transcription.attachmentArray.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Attachments")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(transcription.attachmentArray) { attachment in
                                AttachmentThumbnailView(attachment: attachment)
                                    .frame(width: 100, height: 100)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteAttachment(attachment)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if isEditing {
                Button("Save") {
                    saveChanges()
                    isEditing = false
                }
            } else {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                shareTranscription()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                speechSynthesizer.toggleSpeech(text: transcription.text ?? "")
            } label: {
                Image(systemName: speechSynthesizer.isSpeaking ? "speaker.slash" : "speaker.wave.2")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showImagePicker = true
                } label: {
                    Label("Add Image", systemImage: "photo")
                }
                
                Button {
                    showFilePicker = true
                } label: {
                    Label("Add Document", systemImage: "doc")
                }
            } label: {
                Image(systemName: "paperclip")
            }
        }
    }

    private func handleImageSelection(_ newValue: PhotosPickerItem?) {
        Task {
            if let photoItem = newValue,
               let data = try? await photoItem.loadTransferable(type: Data.self) {
                await MainActor.run {
                    addImageAttachment(data: data)
                    selectedImageItem = nil
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            let selectedFile = try result.get().first
            if let selectedFile = selectedFile {
                if selectedFile.startAccessingSecurityScopedResource() {
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    let data = try Data(contentsOf: selectedFile)
                    let fileName = selectedFile.lastPathComponent
                    let fileType = selectedFile.pathExtension
                    
                    addDocumentAttachment(data: data, fileName: fileName, fileType: fileType)
                }
            }
        } catch {
            print("File import error: \(error)")
        }
    }
    private func saveChanges() {
        transcription.title = editedTitle
        transcription.text = editedText
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
    
    private func shareTranscription() {
        let text = """
        \(transcription.title ?? "Untitled")
        
        \(transcription.text ?? "")
        """
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func addImageAttachment(data: Data) {
        let attachment = Attachment(context: viewContext)
        attachment.id = UUID()
        attachment.data = data
        attachment.type = "image"
        attachment.fileName = "Image \(Date().formatted(.dateTime))"
        attachment.createdAt = Date()
        attachment.transcription = transcription
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving image attachment: \(error)")
        }
    }
    
    private func addDocumentAttachment(data: Data, fileName: String, fileType: String) {
        let attachment = Attachment(context: viewContext)
        attachment.id = UUID()
        attachment.data = data
        attachment.type = "document-\(fileType)"
        attachment.fileName = fileName
        attachment.createdAt = Date()
        attachment.transcription = transcription
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving document attachment: \(error)")
        }
    }
    
    private func deleteAttachment(_ attachment: Attachment) {
        viewContext.delete(attachment)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting attachment: \(error)")
        }
    }
    
    private func shareAttachment(_ attachment: Attachment) {
        guard let data = attachment.data else { return }
        
        let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// Attachment detail view
struct AttachmentDetailView: View {
    let attachment: Attachment
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            if attachment.type == "image", let data = attachment.data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("File preview not available")
                    .foregroundColor(.secondary)
            }
            
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



struct AttachmentThumbnailView: View {
    let attachment: Attachment
    @State private var showingPreview = false
    
    var body: some View {
        VStack {
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
            
            Text(attachment.fileName ?? "File")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .onTapGesture {
            if let data = attachment.data {
                // Create safe filename
                let safeFileName = (attachment.fileName ?? "file")
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: ":", with: "-")
                
                let fileNameWithExt = attachment.type == "image" && !safeFileName.contains(".")
                                    ? safeFileName + ".jpg"
                                    : safeFileName
                
                let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                let fileURL = temporaryDirectoryURL.appendingPathComponent(fileNameWithExt)
                
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
                
                if let fileName = attachment.fileName {
                            let safeFileName = fileName.replacingOccurrences(of: "/", with: "-")
                                                     .replacingOccurrences(of: ":", with: "-")
                            let fileNameWithExt = attachment.type == "image" && !safeFileName.contains(".")
                                                ? safeFileName + ".jpg"
                                                : safeFileName
                            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileNameWithExt)
                            
                            if FileManager.default.fileExists(atPath: fileURL.path) {
                                QuickLookPreview(url: fileURL)
                            }
                        }
            }
        }
    }
}

// QuickLook Preview
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookPreview
        
        init(_ parent: QuickLookPreview) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as NSURL
        }
    }
}




extension Transcription {
    @objc var attachmentArray: [Attachment] {
        let set = attachments as? Set<Attachment> ?? []
        return set.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
    }
}

