import SwiftUI
import CoreData


@main
struct penOCR: App {
    @State private var shouldShowRatingAlert = false
    @State private var isDarkMode = UserDefaults.standard.bool(forKey: "appearance_preference")
    let persistenceController = PersistenceController.shared // CoreData persistence controller
    
    
    
    // Control for launch screen and onboarding visibility
    @State private var showLaunchScreen = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")
    
    init() {
            // Register default preferences
            let defaultPrefs: [String: Any] = [
                "developer_name": "Bruno Felalaga"
            ]
            UserDefaults.standard.register(defaults: defaultPrefs)
            
            
        }
   
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()  // Main app content with CoreData context
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                
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
            }.onAppear {
                checkAndIncrementLaunchCount()
                
                NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { _ in 
                                isDarkMode = UserDefaults.standard.bool(forKey: "appearance_preference")
                            }
            }
            .alert("Enjoying penOCR? Help us with a rating", isPresented: $shouldShowRatingAlert) {
                Button("Rate Now") {
                    // This should take the user to the App Store page for your app
                    if let url = URL(string: "https://apps.apple.com/app/id000000000") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Later", role: .cancel) { }
            }
        }
    }
        
    
    
    private func checkAndIncrementLaunchCount() {
        let defaults = UserDefaults.standard
        let launchCountKey = "app_launch_count"
        let hasRatedKey = "user_has_rated"
        
        if defaults.object(forKey: "Initial Launch") == nil {
            defaults.set(Date(), forKey: "Initial Launch")
        }
        
        // Skip if user has already rated
        if defaults.bool(forKey: hasRatedKey) {
            return
        }
        
        let currentCount = defaults.integer(forKey: launchCountKey) + 1
        defaults.set(currentCount, forKey: launchCountKey)
        
        if currentCount == 3 {
            shouldShowRatingAlert = true
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

