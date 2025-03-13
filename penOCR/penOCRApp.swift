import SwiftUI
import CoreData


@main
struct penOCR: App {
    let persistenceController = PersistenceController.shared // CoreData persistence controller
    
    // Control for launch screen and onboarding visibility
    @State private var showLaunchScreen = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")
   
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()  // Main app content with CoreData context
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                
                // Show launchscreen and dismiss after 2s
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showLaunchScreen = false
                                }
                            }
                        }
                }
                
                // Show onboarding screen after launch screen only for the first launch
                if !showLaunchScreen && showOnboarding {
                    OnboardingView(showOnboarding: $showOnboarding)
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }
}



// Persistence controller for Core Data
struct PersistenceController {
    
    static let shared = PersistenceController() // Singleton instance
    
    let container: NSPersistentContainer // Core Data persistent container for data model
    
    // Initialize persistent container with optional in-memory storage for testing
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Model")
        
        // Configure for in-memory storage if needed, doesnt persist after app terminates
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Load the persistent store and handle errors
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error loading Core Data: \(error.localizedDescription)")
            }
        }
    }
}

