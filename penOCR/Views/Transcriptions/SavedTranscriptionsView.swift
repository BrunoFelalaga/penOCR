import SwiftUI
import CoreData

struct SavedTranscriptionsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transcription.createdAt, ascending: false)],
        animation: .default)
    private var transcriptions: FetchedResults<Transcription>
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTranscription: Transcription?
    @State private var showingDeleteAlert = false
    @State private var transcriptionToDelete: Transcription?
    @State private var searchText = ""
    
    @State private var dateSortAscending = false
    @State private var titleSortAscending = false

    
    
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
            if transcriptions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Saved Transcriptions")
                        .font(.title2)
                    Text("Transcriptions you save will appear here")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredTranscriptions, id: \.id) { transcription in
                        NavigationLink(destination: TranscriptionDetailView(transcription: transcription)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transcription.title ?? "Untitled")
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text(transcription.text ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                Text(transcription.createdAt ?? Date(), format: .dateTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                transcriptionToDelete = transcription
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                shareTranscription(transcription)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search transcriptions")
                .alert("Delete Transcription", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        if let transcription = transcriptionToDelete {
                            deleteTranscription(transcription)
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this transcription? This action cannot be undone.")
                }
                .navigationBarTitle("Saved Transcriptions")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                sortTranscriptionsByDate()
                            } label: {
                                Label("Sort by Date", systemImage: "calendar")
                            }
                            
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
    
    private func deleteTranscription(_ transcription: Transcription) {
        viewContext.delete(transcription)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting transcription: \(error)")
        }
    }
    
    private func shareTranscription(_ transcription: Transcription) {
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
    
    private func sortTranscriptionsByDate() {
        dateSortAscending.toggle()
        let descriptor = NSSortDescriptor(
            keyPath: \Transcription.createdAt,
            ascending: dateSortAscending
        )
        transcriptions.nsSortDescriptors = [descriptor]
    }

    private func sortTranscriptionsByTitle() {
        titleSortAscending.toggle()
        let descriptor = NSSortDescriptor(
            keyPath: \Transcription.title,
            ascending: titleSortAscending
        )
        transcriptions.nsSortDescriptors = [descriptor]
    }
}
