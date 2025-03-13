import SwiftUI

struct MainView: View {
    @State private var selectedTab = 1 
    @State private var dummyImage: UIImage? = nil
    @State private var showImportOptions = false

    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Gallery tab
            GalleryView(switchToGalleryTab: switchToGalleryTab)
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                }
                .tag(0)
            
            CameraView()
                    .tabItem {
                        
                        if selectedTab != 1 {
                            Label("Camera", systemImage: "camera.fill")
                        } else {
                            // This creates an empty tab item
                            Label("", systemImage: "")
                        }
                    }
                    .tag(1)
            
            // Saved Notes tab
            SavedTranscriptionsView()
                .tabItem {
                    Label("Saved", systemImage: "list.bullet")
                }

                .tag(2)
        }
    }
    
    // Function to change tabs
    func switchToGalleryTab() {
       selectedTab = 0
   }
    
    
}



#Preview {
    let previewController = PersistenceController(inMemory: true)
    let context = previewController.container.viewContext
    
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

    
    return MainView()
        .environment(\.managedObjectContext, context)
}

