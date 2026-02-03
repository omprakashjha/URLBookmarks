import Foundation
import CoreData

class CrossPlatformSyncManager: ObservableObject {
    static let shared = CrossPlatformSyncManager()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var pendingConflicts: [BookmarkConflict] = []
    
    private let persistenceController = PersistenceController.shared
    private let exportImportService = ExportImportService.shared
    private var syncTimer: Timer?
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
        case conflictsDetected(Int)
        
        static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.syncing, .syncing), (.success, .success):
                return true
            case (.error(let a), .error(let b)):
                return a == b
            case (.conflictsDetected(let a), .conflictsDetected(let b)):
                return a == b
            default:
                return false
            }
        }
    }
    
    private init() {
        setupPeriodicSync()
        setupRemoteChangeNotifications()
    }
    
    // MARK: - Sync Management
    
    func startSync() {
        guard syncStatus != .syncing else { return }
        
        syncStatus = .syncing
        
        Task {
            await performSync()
        }
    }
    
    func stopSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func setupPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            if self.persistenceController.isSyncEnabled {
                self.startSync()
            }
        }
    }
    
    private func setupRemoteChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: persistenceController.persistentContainer.persistentStoreCoordinator
        )
    }
    
    @objc private func handleRemoteChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.startSync()
        }
    }
    
    private func performSync() async {
        do {
            // Detect conflicts
            let conflicts = await detectConflicts()
            
            if !conflicts.isEmpty {
                await MainActor.run {
                    self.pendingConflicts = conflicts
                    self.syncStatus = .conflictsDetected(conflicts.count)
                }
                return
            }
            
            // Perform sync operations
            try await syncLocalChanges()
            try await fetchRemoteChanges()
            
            await MainActor.run {
                self.lastSyncDate = Date()
                self.syncStatus = .success
                
                // Reset to idle after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.syncStatus = .idle
                }
            }
            
        } catch {
            await MainActor.run {
                self.syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Conflict Detection
    
    private func detectConflicts() async -> [BookmarkConflict] {
        // This would integrate with CloudKit change detection
        // For now, we'll simulate conflict detection
        
        let fetchRequest = URLBookmark.activeFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "modifiedAt > %@", (lastSyncDate ?? Date.distantPast) as CVarArg)
        
        do {
            let localChanges = try persistenceController.context.fetch(fetchRequest)
            var conflicts: [BookmarkConflict] = []
            
            // Simulate remote changes that conflict with local changes
            for bookmark in localChanges {
                guard let url = bookmark.url else { continue }
                // In a real implementation, you would:
                // 1. Fetch the same bookmark from CloudKit
                // 2. Compare modification dates and content
                // 3. Create conflicts for items modified on both sides
                
                if shouldSimulateConflict(bookmark) {
                    guard let id = bookmark.id,
                          let createdAt = bookmark.createdAt else {
                        continue
                    }
                    let remoteData = BookmarkExportData(
                        id: id.uuidString,
                        url: url,
                        title: (bookmark.title ?? "") + " (Remote)",
                        notes: (bookmark.notes ?? "") + " (Modified remotely)",
                        createdAt: createdAt,
                        modifiedAt: Date(),
                        tags: [],
                        metadata: BookmarkMetadata(
                            domain: extractDomain(from: url),
                            isSecure: url.hasPrefix("https://")
                        )
                    )
                    
                    conflicts.append(BookmarkConflict(
                        local: bookmark,
                        remote: remoteData,
                        resolution: .merge // Default resolution
                    ))
                }
            }
            
            return conflicts
            
        } catch {
            print("Conflict detection error: \(error)")
            return []
        }
    }
    
    private func shouldSimulateConflict(_ bookmark: URLBookmark) -> Bool {
        // Simulate conflicts for demonstration
        // In production, this would be based on actual CloudKit data
        return (bookmark.url?.contains("example") ?? false) && Int.random(in: 1...10) <= 2
    }
    
    // MARK: - Sync Operations
    
    private func syncLocalChanges() async throws {
        // Get locally modified bookmarks since last sync
        let fetchRequest = URLBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "modifiedAt > %@", (lastSyncDate ?? Date.distantPast) as CVarArg)
        
        let localChanges = try persistenceController.context.fetch(fetchRequest)
        
        // In a real implementation, push these to CloudKit
        print("Syncing \(localChanges.count) local changes to remote")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func fetchRemoteChanges() async throws {
        // In a real implementation, fetch changes from CloudKit
        print("Fetching remote changes")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflicts(with resolutions: [String: ConflictResolution]) {
        var updatedConflicts: [BookmarkConflict] = []
        
        for conflict in pendingConflicts {
            guard let localId = conflict.local.id else { continue }
            if let resolution = resolutions[localId.uuidString] {
                var updatedConflict = conflict
                updatedConflict = BookmarkConflict(
                    local: conflict.local,
                    remote: conflict.remote,
                    resolution: resolution
                )
                updatedConflicts.append(updatedConflict)
            } else {
                updatedConflicts.append(conflict)
            }
        }
        
        let result = exportImportService.resolveConflicts(updatedConflicts)
        
        if result.failed == 0 {
            pendingConflicts.removeAll()
            syncStatus = .success
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
        } else {
            syncStatus = .error("Failed to resolve \(result.failed) conflicts")
        }
    }
    
    func resolveAllConflicts(with strategy: ConflictResolution) {
        let resolutions = Dictionary(uniqueKeysWithValues: 
            pendingConflicts.compactMap { conflict -> (String, ConflictResolution)? in
                guard let id = conflict.local.id else { return nil }
                return (id.uuidString, strategy)
            }
        )
        resolveConflicts(with: resolutions)
    }
    
    // MARK: - Backup and Restore
    
    func createBackup() -> BackupResult {
        let exportResult = exportImportService.exportBookmarks(format: .json)
        
        switch exportResult {
        case .success(let data, let filename, _):
            let backup = BackupInfo(
                id: UUID(),
                filename: filename,
                createdAt: Date(),
                platform: getCurrentPlatform(),
                bookmarkCount: getBookmarkCount(),
                size: data.count
            )
            
            // Save backup metadata
            saveBackupMetadata(backup)
            
            return .success(backup, data)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func restoreFromBackup(_ data: Data) -> RestoreResult {
        let importResult = exportImportService.importBookmarks(from: data, format: .json)
        
        switch importResult {
        case .success(let summary):
            return .success(summary)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getAvailableBackups() -> [BackupInfo] {
        return loadBackupMetadata()
    }
    
    // MARK: - Migration Tools
    
    func migrateFromLegacyFormat(_ legacyData: Data) -> MigrationResult {
        // Handle migration from older app versions or other bookmark managers
        
        do {
            // Try to parse as various legacy formats
            if let safariBookmarks = try? parseSafariBookmarks(legacyData) {
                return processMigrationData(safariBookmarks, source: "Safari")
            }
            
            if let chromeBookmarks = try? parseChromeBookmarks(legacyData) {
                return processMigrationData(chromeBookmarks, source: "Chrome")
            }
            
            if let firefoxBookmarks = try? parseFirefoxBookmarks(legacyData) {
                return processMigrationData(firefoxBookmarks, source: "Firefox")
            }
            
            return .failure("Unsupported legacy format")
            
        } catch {
            return .failure("Migration failed: \(error.localizedDescription)")
        }
    }
    
    private func parseSafariBookmarks(_ data: Data) throws -> [BookmarkExportData] {
        // Parse Safari plist format
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw MigrationError.invalidFormat
        }
        
        // Extract bookmarks from Safari plist structure
        return extractBookmarksFromSafariPlist(plist)
    }
    
    private func parseChromeBookmarks(_ data: Data) throws -> [BookmarkExportData] {
        // Parse Chrome JSON format
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let roots = json?["roots"] as? [String: Any] else {
            throw MigrationError.invalidFormat
        }
        
        return extractBookmarksFromChromeJSON(roots)
    }
    
    private func parseFirefoxBookmarks(_ data: Data) throws -> [BookmarkExportData] {
        // Parse Firefox HTML format
        guard let html = String(data: data, encoding: .utf8) else {
            throw MigrationError.invalidFormat
        }
        
        return extractBookmarksFromFirefoxHTML(html)
    }
    
    private func processMigrationData(_ bookmarks: [BookmarkExportData], source: String) -> MigrationResult {
        let importResult = exportImportService.importBookmarks(from: try! JSONEncoder().encode(bookmarks), format: .json)
        
        switch importResult {
        case .success(let summary):
            return .success(MigrationSummary(
                source: source,
                imported: summary.imported,
                skipped: summary.skipped,
                errors: summary.errors
            ))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentPlatform() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Unknown"
        #endif
    }
    
    private func getBookmarkCount() -> Int {
        let fetchRequest = URLBookmark.activeFetchRequest()
        return (try? persistenceController.context.count(for: fetchRequest)) ?? 0
    }
    
    private func extractDomain(from url: String) -> String {
        guard let urlObj = URL(string: url) else { return "" }
        return urlObj.host ?? ""
    }
    
    private func saveBackupMetadata(_ backup: BackupInfo) {
        var backups = loadBackupMetadata()
        backups.append(backup)
        
        // Keep only last 10 backups
        if backups.count > 10 {
            backups = Array(backups.suffix(10))
        }
        
        if let data = try? JSONEncoder().encode(backups) {
            UserDefaults.standard.set(data, forKey: "BackupMetadata")
        }
    }
    
    private func loadBackupMetadata() -> [BackupInfo] {
        guard let data = UserDefaults.standard.data(forKey: "BackupMetadata"),
              let backups = try? JSONDecoder().decode([BackupInfo].self, from: data) else {
            return []
        }
        return backups
    }
    
    // Placeholder implementations for browser bookmark parsing
    private func extractBookmarksFromSafariPlist(_ plist: [String: Any]) -> [BookmarkExportData] {
        // Implementation would parse Safari's plist structure
        return []
    }
    
    private func extractBookmarksFromChromeJSON(_ roots: [String: Any]) -> [BookmarkExportData] {
        // Implementation would parse Chrome's JSON structure
        return []
    }
    
    private func extractBookmarksFromFirefoxHTML(_ html: String) -> [BookmarkExportData] {
        // Implementation would parse Firefox's HTML export format
        return []
    }
}

// MARK: - Additional Data Models

struct BackupInfo: Codable {
    let id: UUID
    let filename: String
    let createdAt: Date
    let platform: String
    let bookmarkCount: Int
    let size: Int
}

enum BackupResult {
    case success(BackupInfo, Data)
    case failure(String)
}

enum RestoreResult {
    case success(ImportSummary)
    case failure(String)
}

enum MigrationResult {
    case success(MigrationSummary)
    case failure(String)
}

struct MigrationSummary {
    let source: String
    let imported: Int
    let skipped: Int
    let errors: [String]
}

enum MigrationError: Error {
    case invalidFormat
    case unsupportedVersion
}
