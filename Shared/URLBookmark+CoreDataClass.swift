import Foundation
import CoreData

// MARK: - URLBookmark Entity
@objc(URLBookmark)
public class URLBookmark: NSManagedObject, Identifiable {
    
}

extension URLBookmark {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<URLBookmark> {
        return NSFetchRequest<URLBookmark>(entityName: "URLBookmark")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var url: String?
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var isArchived: Bool
}

// MARK: - Convenience Methods
extension URLBookmark {
    
    convenience init(context: NSManagedObjectContext, url: String, title: String? = nil, notes: String? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.url = url
        self.title = title
        self.notes = notes
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isArchived = false
    }
    
    func updateModifiedDate() {
        self.modifiedAt = Date()
    }
    
    func markAsDeleted() {
        self.isArchived = true
        self.updateModifiedDate()
    }
}

// MARK: - Search and Filtering
extension URLBookmark {
    
    static func searchPredicate(for searchText: String) -> NSPredicate {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return NSPredicate(format: "isArchived == NO")
        }
        
        return NSPredicate(format: "isArchived == NO AND (url CONTAINS[cd] %@ OR title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@)", 
                          trimmedText, trimmedText, trimmedText)
    }
    
    static func activeFetchRequest() -> NSFetchRequest<URLBookmark> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \URLBookmark.modifiedAt, ascending: false)]
        return request
    }
}
