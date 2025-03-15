import SwiftUI

// MainView: Primary navigation container using TabView
// Manages tab selection and provides interface to access Gallery, Camera and Saved Transcriptions
struct MainView: View {
    @State private var selectedTab = 1 
    @State private var dummyImage: UIImage? = nil
    @State private var showImportOptions = false

    
    var body: some View {
        
        // Tab-based navigation interface
        TabView(selection: $selectedTab) {
            
            // Gallery tab - displays saved images
            GalleryView(switchToGalleryTab: switchToGalleryTab)
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                }
                .tag(0)
            
            // Camera tab - handles photo capture
            CameraView()
                    .tabItem {
                        // Show Empty label when selected to avoid interfering with camera shutter button
                        if selectedTab != 1 {
                            Label("Camera", systemImage: "camera.fill")
                        } else {
                            Label("", systemImage: "")
                        }
                    }
                    .tag(1)
            
            // Saved Notes tab - manages transcribed text content
            SavedTranscriptionsView()
                .tabItem {
                    Label("Saved", systemImage: "list.bullet")
                }

                .tag(2)
        }
        .onChange(of: selectedTab) { newValue in
            print("Tab changed to: \(newValue)")
        }
    }
    
    // Navigation helper to programmatically switch to gallery tab
    func switchToGalleryTab() {
       selectedTab = 0
   }
    
    
}



// SwiftUI Preview with sample CoreData content
#Preview {
    // Create in-memory persistence container for preview
    let previewController = PersistenceController(inMemory: true)
    let context = previewController.container.viewContext
    
    // Sample transcription data for preview
    let sampleTranscription1 = Transcription(context: context)
    sampleTranscription1.id = UUID()
    sampleTranscription1.title = "Meeting Notes"
    sampleTranscription1.text = "Sample text..."
    sampleTranscription1.createdAt = Date()
    
    let sampleTranscription2 = Transcription(context: context)
    sampleTranscription2.id = UUID()
    sampleTranscription2.title = "Shopping List"
    sampleTranscription2.text = "Sample content..."
    sampleTranscription2.createdAt = Date()
    
    try? context.save()

    
    // Return preview with CoreData context
    return MainView()
        .environment(\.managedObjectContext, context)
}

