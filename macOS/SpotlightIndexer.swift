import Foundation
import CoreSpotlight
import MobileCoreServices
import CoreData

class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    private let searchableIndex = CSSearchableIndex.default()
    
    private init() {}
    
    func indexBookmark(_ bookmark: URLBookmark) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .url)
        
        // Basic attributes
        attributeSet.title = bookmark.title ?? bookmark.url
        attributeSet.contentDescription = bookmark.notes
        attributeSet.url = URL(string: bookmark.url)
        
        // Additional metadata
        attributeSet.keywords = [bookmark.url, bookmark.title ?? ""].compactMap { $0 }
        attributeSet.contentCreationDate = bookmark.createdAt
        attributeSet.contentModificationDate = bookmark.modifiedAt
        
        // App-specific attributes
        attributeSet.relatedUniqueIdentifier = bookmark.id.uuidString
        
        // Create searchable item
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: bookmark.id.uuidString,
            domainIdentifier: "com.urlbookmarks.app.bookmarks",
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
        searchableIndex.deleteSearchableItems(withIdentifiers: [bookmark.id.uuidString]) { error in
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
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND isDeleted == NO", uuid as CVarArg)
        
        do {
            let bookmarks = try persistenceController.context.fetch(fetchRequest)
            if let bookmark = bookmarks.first {
                // Open the URL
                if let url = URL(string: bookmark.url) {
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
