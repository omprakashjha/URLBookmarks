import Foundation
import Network

class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isOnline = true
    @Published var offlineQueue: [OfflineOperation] = []
    @Published var offlineMode = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let persistenceController = PersistenceController.shared
    
    private init() {
        startNetworkMonitoring()
        loadOfflineQueue()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOnline = self?.isOnline ?? true
                self?.isOnline = path.status == .satisfied
                
                // Process offline queue when coming back online
                if !wasOnline && self?.isOnline == true {
                    self?.processOfflineQueue()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Offline Operations
    
    func queueOperation(_ operation: OfflineOperation) {
        offlineQueue.append(operation)
        saveOfflineQueue()
        
        // Try to process immediately if online
        if isOnline {
            processOfflineQueue()
        }
    }
    
    private func processOfflineQueue() {
        guard isOnline && !offlineQueue.isEmpty else { return }
        
        let operations = offlineQueue
        offlineQueue.removeAll()
        saveOfflineQueue()
        
        for operation in operations {
            processOperation(operation)
        }
    }
    
    private func processOperation(_ operation: OfflineOperation) {
        switch operation.type {
        case .addBookmark:
            if let data = operation.data as? [String: Any],
               let url = data["url"] as? String {
                _ = persistenceController.addURL(
                    url,
                    title: data["title"] as? String,
                    notes: data["notes"] as? String
                )
            }
            
        case .updateBookmark:
            if let data = operation.data as? [String: Any],
               let id = data["id"] as? String,
               let uuid = UUID(uuidString: id) {
                updateBookmarkFromOfflineData(uuid: uuid, data: data)
            }
            
        case .deleteBookmark:
            if let data = operation.data as? [String: Any],
               let id = data["id"] as? String,
               let uuid = UUID(uuidString: id) {
                deleteBookmarkFromOfflineData(uuid: uuid)
            }
        }
    }
    
    private func updateBookmarkFromOfflineData(uuid: UUID, data: [String: Any]) {
        let fetchRequest = URLBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        do {
            let bookmarks = try persistenceController.context.fetch(fetchRequest)
            if let bookmark = bookmarks.first {
                bookmark.title = data["title"] as? String
                bookmark.notes = data["notes"] as? String
                bookmark.updateModifiedDate()
                persistenceController.save()
            }
        } catch {
            print("Failed to update bookmark from offline data: \(error)")
        }
    }
    
    private func deleteBookmarkFromOfflineData(uuid: UUID) {
        let fetchRequest = URLBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        do {
            let bookmarks = try persistenceController.context.fetch(fetchRequest)
            if let bookmark = bookmarks.first {
                persistenceController.deleteBookmark(bookmark)
            }
        } catch {
            print("Failed to delete bookmark from offline data: \(error)")
        }
    }
    
    // MARK: - Offline Cache Management
    
    func enableOfflineMode() {
        offlineMode = true
        cacheEssentialData()
    }
    
    func disableOfflineMode() {
        offlineMode = false
    }
    
    private func cacheEssentialData() {
        // Cache recent bookmarks for offline access
        let fetchRequest = URLBookmark.activeFetchRequest()
        fetchRequest.fetchLimit = 100 // Cache last 100 bookmarks
        
        do {
            let bookmarks = try persistenceController.context.fetch(fetchRequest)
            let cacheData = bookmarks.compactMap { bookmark -> [String: Any]? in
                guard let id = bookmark.id,
                      let url = bookmark.url,
                      let createdAt = bookmark.createdAt,
                      let modifiedAt = bookmark.modifiedAt else {
                    return nil
                }
                return [
                    "id": id.uuidString,
                    "url": url,
                    "title": bookmark.title ?? "",
                    "notes": bookmark.notes ?? "",
                    "createdAt": createdAt.timeIntervalSince1970,
                    "modifiedAt": modifiedAt.timeIntervalSince1970
                ]
            }
            
            UserDefaults.standard.set(cacheData, forKey: "OfflineBookmarkCache")
        } catch {
            print("Failed to cache bookmarks: \(error)")
        }
    }
    
    func getCachedBookmarks() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "OfflineBookmarkCache") as? [[String: Any]] ?? []
    }
    
    // MARK: - Persistence
    
    private func saveOfflineQueue() {
        do {
            let data = try JSONEncoder().encode(offlineQueue)
            UserDefaults.standard.set(data, forKey: "OfflineQueue")
        } catch {
            print("Failed to save offline queue: \(error)")
        }
    }
    
    private func loadOfflineQueue() {
        guard let data = UserDefaults.standard.data(forKey: "OfflineQueue") else { return }
        
        do {
            offlineQueue = try JSONDecoder().decode([OfflineOperation].self, from: data)
        } catch {
            print("Failed to load offline queue: \(error)")
        }
    }
    
    // MARK: - Utility
    
    func clearOfflineData() {
        offlineQueue.removeAll()
        UserDefaults.standard.removeObject(forKey: "OfflineQueue")
        UserDefaults.standard.removeObject(forKey: "OfflineBookmarkCache")
    }
}

// MARK: - Data Models

struct OfflineOperation: Codable {
    let id: UUID
    let type: OperationType
    let timestamp: Date
    let data: CodableAny
    
    enum OperationType: String, Codable {
        case addBookmark
        case updateBookmark
        case deleteBookmark
    }
    
    init(type: OperationType, data: [String: Any]) {
        self.id = UUID()
        self.type = type
        self.timestamp = Date()
        self.data = CodableAny(data)
    }
}

struct CodableAny: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let dict = try? container.decode([String: CodableAny].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([CodableAny].self) {
            value = array.map { $0.value }
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { CodableAny($0) })
        case let array as [Any]:
            try container.encode(array.map { CodableAny($0) })
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

extension CodableAny {
    var data: [String: Any]? {
        return value as? [String: Any]
    }
}
