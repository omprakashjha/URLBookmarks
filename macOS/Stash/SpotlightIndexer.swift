import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import CoreData
import AppKit

class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    private let searchableIndex = CSSearchableIndex.default()
    
    private init() {}
    
    func indexBookmark(_ bookmark: URLBookmark) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .url)
        
        // Basic attributes
        attributeSet.title = bookmark.title ?? bookmark.url ?? "Untitled"
        attributeSet.contentDescription = bookmark.notes
        if let urlString = bookmark.url {
            attributeSet.url = URL(string: urlString)
        }
        
        // Additional metadata
        attributeSet.keywords = [bookmark.url, bookmark.title].compactMap { $0 }
        attributeSet.contentCreationDate = bookmark.createdAt
        attributeSet.contentModificationDate = bookmark.modifiedAt
        
        // App-specific attributes
        if let id = bookmark.id {
            attributeSet.relatedUniqueIdentifier = id.uuidString
        }
        
        // Create searchable item
        guard let id = bookmark.id else { return }
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: id.uuidString,
            domainIdentifier: "com.stash.app.bookmarks",
            attributeSet: attributeSet
        )
        
        // Index the item
        searchableIndex.indexSearchableItems([searchableItem]) { error in
            if let error = error {
                print("Spotlight indexing error: \(error)")
            }
        }
    }
    
    func removeBookmark(_ bookmark: URLBookmark) {
        guard let id = bookmark.id else { return }
        searchableIndex.deleteSearchableItems(withIdentifiers: [id.uuidString]) { error in
            if let error = error {
                print("Spotlight removal error: \(error)")
            }
        }
    }
    
    func reindexAllBookmarks() {
        let persistenceController = PersistenceController.shared
        let fetchRequest = URLBookmark.activeFetchRequest()
        
        do {
            let bookmarks = try persistenceController.context.fetch(fetchRequest)
            
            // Clear existing index
            searchableIndex.deleteAllSearchableItems { [weak self] error in
                if let error = error {
                    print("Spotlight clear error: \(error)")
                    return
                }
                
                // Reindex all bookmarks
                for bookmark in bookmarks {
                    self?.indexBookmark(bookmark)
                }
            }
        } catch {
            print("Failed to fetch bookmarks for reindexing: \(error)")
        }
    }
    
    func handleSpotlightSelection(identifier: String) -> Bool {
        guard let uuid = UUID(uuidString: identifier) else { return false }
        
        let persistenceController = PersistenceController.shared
        let fetchRequest = URLBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND isArchived == NO", uuid as CVarArg)
        
        do {
            let bookmarks = try persistenceController.context.fetch(fetchRequest)
            if let bookmark = bookmarks.first, let urlString = bookmark.url {
                // Open the URL
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                    return true
                }
            }
        } catch {
            print("Failed to fetch bookmark for Spotlight selection: \(error)")
        }
        
        return false
    }
}
