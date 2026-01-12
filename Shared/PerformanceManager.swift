import Foundation
import CoreData

class PerformanceManager {
    static let shared = PerformanceManager()
    
    private let persistenceController = PersistenceController.shared
    private var searchCache: [String: [URLBookmark]] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {
        setupPerformanceOptimizations()
    }
    
    // MARK: - Search Optimization
    
    func performOptimizedSearch(_ searchText: String) -> [URLBookmark] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Return cached results if available and fresh
        if let cachedResults = getCachedResults(for: trimmedText) {
            return cachedResults
        }
        
        // Perform search with optimizations
        let results = executeOptimizedSearch(trimmedText)
        
        // Cache results
        cacheResults(results, for: trimmedText)
        
        return results
    }
    
    private func getCachedResults(for searchText: String) -> [URLBookmark]? {
        guard let results = searchCache[searchText],
              let timestamp = cacheTimestamps[searchText],
              Date().timeIntervalSince(timestamp) < cacheTimeout else {
            return nil
        }
        
        return results
    }
    
    private func executeOptimizedSearch(_ searchText: String) -> [URLBookmark] {
        guard !searchText.isEmpty else {
            return fetchRecentBookmarks()
        }
        
        let fetchRequest = URLBookmark.fetchRequest()
        
        // Use compound predicate for better performance
        let notDeletedPredicate = NSPredicate(format: "isDeleted == NO")
        let searchPredicate = NSPredicate(format: "url CONTAINS[cd] %@ OR title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", 
                                        searchText, searchText, searchText)
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notDeletedPredicate, searchPredicate])
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \URLBookmark.modifiedAt, ascending: false)
        ]
        
        // Limit results for performance
        fetchRequest.fetchLimit = 100
        
        do {
            return try persistenceController.context.fetch(fetchRequest)
        } catch {
            print("Search error: \(error)")
            return []
        }
    }
    
    private func fetchRecentBookmarks() -> [URLBookmark] {
        let fetchRequest = URLBookmark.activeFetchRequest()
        fetchRequest.fetchLimit = 50 // Show recent 50 by default
        
        do {
            return try persistenceController.context.fetch(fetchRequest)
        } catch {
            print("Recent bookmarks fetch error: \(error)")
            return []
        }
    }
    
    private func cacheResults(_ results: [URLBookmark], for searchText: String) {
        searchCache[searchText] = results
        cacheTimestamps[searchText] = Date()
        
        // Clean old cache entries
        cleanExpiredCache()
    }
    
    private func cleanExpiredCache() {
        let now = Date()
        let expiredKeys = cacheTimestamps.compactMap { key, timestamp in
            now.timeIntervalSince(timestamp) > cacheTimeout ? key : nil
        }
        
        for key in expiredKeys {
            searchCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
    }
    
    // MARK: - Virtual Scrolling Support
    
    func getBookmarksBatch(offset: Int, limit: Int, searchText: String = "") -> [URLBookmark] {
        let fetchRequest = URLBookmark.fetchRequest()
        
        if searchText.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "isDeleted == NO")
        } else {
            let notDeletedPredicate = NSPredicate(format: "isDeleted == NO")
            let searchPredicate = NSPredicate(format: "url CONTAINS[cd] %@ OR title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", 
                                            searchText, searchText, searchText)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notDeletedPredicate, searchPredicate])
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \URLBookmark.modifiedAt, ascending: false)]
        fetchRequest.fetchOffset = offset
        fetchRequest.fetchLimit = limit
        
        do {
            return try persistenceController.context.fetch(fetchRequest)
        } catch {
            print("Batch fetch error: \(error)")
            return []
        }
    }
    
    func getTotalBookmarkCount(searchText: String = "") -> Int {
        let fetchRequest = URLBookmark.fetchRequest()
        
        if searchText.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "isDeleted == NO")
        } else {
            let notDeletedPredicate = NSPredicate(format: "isDeleted == NO")
            let searchPredicate = NSPredicate(format: "url CONTAINS[cd] %@ OR title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", 
                                            searchText, searchText, searchText)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notDeletedPredicate, searchPredicate])
        }
        
        do {
            return try persistenceController.context.count(for: fetchRequest)
        } catch {
            print("Count fetch error: \(error)")
            return 0
        }
    }
    
    // MARK: - Core Data Optimizations
    
    private func setupPerformanceOptimizations() {
        // Configure Core Data for better performance
        let context = persistenceController.context
        
        // Batch processing
        context.automaticallyMergesChangesFromParent = true
        
        // Memory management
        context.undoManager = nil // Disable undo for better performance
        
        // Setup periodic cleanup
        setupPeriodicCleanup()
    }
    
    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
            self.performMaintenanceTasks()
        }
    }
    
    private func performMaintenanceTasks() {
        // Clean expired cache
        cleanExpiredCache()
        
        // Refresh Core Data objects
        persistenceController.context.refreshAllObjects()
        
        // Clean up deleted bookmarks older than 30 days
        cleanupOldDeletedBookmarks()
    }
    
    private func cleanupOldDeletedBookmarks() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let fetchRequest = URLBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDeleted == YES AND modifiedAt < %@", thirtyDaysAgo as CVarArg)
        
        do {
            let oldDeletedBookmarks = try persistenceController.context.fetch(fetchRequest)
            
            for bookmark in oldDeletedBookmarks {
                persistenceController.context.delete(bookmark)
            }
            
            if !oldDeletedBookmarks.isEmpty {
                persistenceController.save()
                print("Cleaned up \(oldDeletedBookmarks.count) old deleted bookmarks")
            }
        } catch {
            print("Cleanup error: \(error)")
        }
    }
    
    // MARK: - Memory Management
    
    func clearCaches() {
        searchCache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    func getMemoryUsage() -> (searchCache: Int, totalBookmarks: Int) {
        let searchCacheCount = searchCache.values.reduce(0) { $0 + $1.count }
        let totalBookmarks = getTotalBookmarkCount()
        
        return (searchCache: searchCacheCount, totalBookmarks: totalBookmarks)
    }
    
    // MARK: - Analytics
    
    func getPerformanceMetrics() -> PerformanceMetrics {
        let memoryUsage = getMemoryUsage()
        
        return PerformanceMetrics(
            totalBookmarks: memoryUsage.totalBookmarks,
            cachedSearchResults: searchCache.count,
            cachedBookmarks: memoryUsage.searchCache,
            cacheHitRate: calculateCacheHitRate(),
            averageSearchTime: 0 // Would be calculated with actual timing
        )
    }
    
    private func calculateCacheHitRate() -> Double {
        // Simplified cache hit rate calculation
        // In a real implementation, you would track hits vs misses
        return searchCache.isEmpty ? 0.0 : 0.75
    }
}

// MARK: - Data Models

struct PerformanceMetrics {
    let totalBookmarks: Int
    let cachedSearchResults: Int
    let cachedBookmarks: Int
    let cacheHitRate: Double
    let averageSearchTime: TimeInterval
}
