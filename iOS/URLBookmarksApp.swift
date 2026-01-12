import SwiftUI

@main
struct URLBookmarksApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(persistenceController)
        }
    }
}
