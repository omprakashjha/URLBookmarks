import Foundation
import CoreData

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Stash")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Sync Control
    @Published var isSyncEnabled: Bool = false
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Save Context
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    func manualSync() {
        // CloudKit sync disabled
    }
}

// MARK: - URL Management
extension PersistenceController {
    
    func addURL(_ urlString: String, title: String? = nil, notes: String? = nil) -> URLBookmark? {
        // Validate URL
        guard URL(string: urlString) != nil else { return nil }
        
        // Check for duplicates
        let fetchRequest = URLBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "url == %@ AND isArchived == NO", urlString)
        
        do {
            let existingBookmarks = try context.fetch(fetchRequest)
            if !existingBookmarks.isEmpty {
                return existingBookmarks.first
            }
        } catch {
            print("Error checking for duplicates: \(error)")
        }
        
        // Create new bookmark
        let bookmark = URLBookmark(context: context, url: urlString, title: title, notes: notes)
        save()
        
        #if os(macOS)
        // Index for Spotlight search
        SpotlightIndexer.shared.indexBookmark(bookmark)
        #endif
        
        return bookmark
    }
    
    func deleteBookmark(_ bookmark: URLBookmark) {
        #if os(macOS)
        // Remove from Spotlight index
        SpotlightIndexer.shared.removeBookmark(bookmark)
        #endif
        
        bookmark.markAsDeleted()
        save()
    }
    
    func searchBookmarks(_ searchText: String) -> [URLBookmark] {
        let fetchRequest = URLBookmark.fetchRequest()
        fetchRequest.predicate = URLBookmark.searchPredicate(for: searchText)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \URLBookmark.modifiedAt, ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Search error: \(error)")
            return []
        }
    }
}
