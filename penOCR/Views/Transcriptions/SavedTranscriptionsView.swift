import SwiftUI
import CoreData


// SavedTranscriptionsView: Displays and manages saved transcriptions with search and sort functionality
// Implements CoreData fetch and filtering capabilities
struct SavedTranscriptionsView: View {
    // Fetches transcriptions in descending order by creation date
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transcription.createdAt, ascending: false)],
        animation: .default)
    private var transcriptions: FetchedResults<Transcription>
    
    // Environment and state variables for view management
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTranscription: Transcription?
    @State private var showingDeleteAlert = false
    @State private var transcriptionToDelete: Transcription?
    @State private var searchText = ""
    
    // Sort order state variables
    @State private var dateSortAscending = false
    @State private var titleSortAscending = false

    
    // Filters transcriptions based on search text in title or content
    var filteredTranscriptions: [Transcription] {
        if searchText.isEmpty {
            return Array(transcriptions)
        } else {
            return transcriptions.filter {
                $0.title?.localizedCaseInsensitiveContains(searchText) ?? false ||
                $0.text?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    
    var body: some View {
        NavigationView {
            // Empty state display when no transcriptions exist
            if transcriptions.isEmpty {
                VStack(spacing: 20) {
                    // Empty state icon
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Saved Transcriptions") // Empty state title
                        .font(.title2)
                    Text("Transcriptions you save will appear here") // Empty state description
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List { // List of transcriptions when data exists
                    ForEach(filteredTranscriptions, id: \.id) { transcription in
                        NavigationLink(destination: TranscriptionDetailView(transcription: transcription)) {
                            VStack(alignment: .leading, spacing: 4) {
                                // Transcription title display
                                Text(transcription.title ?? "Untitled")
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                // Preview of transcription content
                                Text(transcription.text ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                // Timestamp of when transcription was created
                                Text(transcription.createdAt ?? Date(), format: .dateTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) { // swipe to Delete action with confirmation
                            // Delete action  button
                            Button(role: .destructive) {
                                transcriptionToDelete = transcription
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            // Share action for exporting transcription
                            Button {
                                shareTranscription(transcription)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search transcriptions") // Search functionality for filtering transcriptions
                .alert("Delete Transcription", isPresented: $showingDeleteAlert) { // Confirmation dialog for deleting transcriptions with safety warning
                    
                    // Cancel button to dismiss alert
                    Button("Cancel", role: .cancel) {}
                    // Delete button with confirmation action
                    Button("Delete", role: .destructive) {
                        if let transcription = transcriptionToDelete {
                            deleteTranscription(transcription)
                        }
                    }
                } message: { // Warning message about permanent deletion
                    Text("Are you sure you want to delete this transcription? This action cannot be undone.")
                }
                .navigationBarTitle("Saved Transcriptions")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // Sort options menu for organizing transcriptions
                        Menu {
                            
                            // Date sort option
                            Button {
                                sortTranscriptionsByDate()
                            } label: {
                                Label("Sort by Date", systemImage: "calendar")
                            }
                            
                            // Title sort option
                            Button {
                                sortTranscriptionsByTitle()
                            } label: {
                                Label("Sort by Title", systemImage: "textformat")
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
            }
        }
    }
    
    // Removes a transcription from CoreData and saves the context
    private func deleteTranscription(_ transcription: Transcription) {
        viewContext.delete(transcription) // Remove transcription from managed object context
        
        do {
            try viewContext.save() // Persist changes to storage
        } catch {
            print("Error deleting transcription: \(error)")
        }
    }
    
    // Creates and presents a share sheet with the transcription content
    private func shareTranscription(_ transcription: Transcription) {
        
        // Prepare formatted text with title and content
        let text = """
        \(transcription.title ?? "Untitled")
        
        \(transcription.text ?? "")
        """
        
        // Create and configure iOS share sheet
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // Present the share sheet from the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    // Toggles date sort order and applies the new sort descriptor
    private func sortTranscriptionsByDate() {
        
        dateSortAscending.toggle() // Switch between ascending/descending
        let descriptor = NSSortDescriptor(
            keyPath: \Transcription.createdAt,
            ascending: dateSortAscending
        )  // Create sort descriptor based on creation date
        
        
        transcriptions.nsSortDescriptors = [descriptor] // Apply sort to fetched results
    }

    // Toggles title sort order and applies the new sort descriptor
    private func sortTranscriptionsByTitle() {
        titleSortAscending.toggle() // Switch between ascending/descending
        let descriptor = NSSortDescriptor(
            keyPath: \Transcription.title,
            ascending: titleSortAscending
        )  // Create sort descriptor based on title
        transcriptions.nsSortDescriptors = [descriptor] // Apply sort to fetched results
    }
}
