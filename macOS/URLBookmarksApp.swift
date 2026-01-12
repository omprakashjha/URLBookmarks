import SwiftUI
import AppKit

@main
struct URLBookmarksApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(persistenceController)
                .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                    handleSpotlightSelection(userActivity)
                }
        }
        .commands {
            URLBookmarksCommands()
        }
        
        Settings {
            SettingsView()
                .environmentObject(persistenceController)
        }
    }
    
    private func handleSpotlightSelection(_ userActivity: NSUserActivity) {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return
        }
        
        _ = SpotlightIndexer.shared.handleSpotlightSelection(identifier: identifier)
    }
}

struct URLBookmarksCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Add URL...") {
                NotificationCenter.default.post(name: .showAddURL, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        
        CommandGroup(after: .textEditing) {
            Button("Search URLs...") {
                NotificationCenter.default.post(name: .focusSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
        }
        
        CommandGroup(after: .importExport) {
            Button("Export URLs...") {
                NotificationCenter.default.post(name: .exportURLs, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            
            Button("Import URLs...") {
                NotificationCenter.default.post(name: .importURLs, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let showAddURL = Notification.Name("showAddURL")
    static let focusSearch = Notification.Name("focusSearch")
    static let exportURLs = Notification.Name("exportURLs")
    static let importURLs = Notification.Name("importURLs")
}
