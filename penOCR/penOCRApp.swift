import SwiftUI
import CoreData


@main
struct penOCR: App {
    let persistenceController = PersistenceController.shared
    @State private var showLaunchScreen = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                
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
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Model")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error loading Core Data: \(error.localizedDescription)")
            }
        }
    }
}

