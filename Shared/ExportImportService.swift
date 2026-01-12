import Foundation
import CoreData

class ExportImportService {
    static let shared = ExportImportService()
    private let persistenceController = PersistenceController.shared
    
    private init() {}
    
    // MARK: - Export Functionality
    
    func exportBookmarks(format: ExportFormat = .json) -> ExportResult {
        let fetchRequest = URLBookmark.activeFetchRequest()
        
        do {
            let bookmarks = try persistenceController.context.fetch(fetchRequest)
            
            switch format {
            case .json:
                return exportAsJSON(bookmarks)
            case .csv:
                return exportAsCSV(bookmarks)
            case .html:
                return exportAsHTML(bookmarks)
            }
        } catch {
            return .failure("Failed to fetch bookmarks: \(error.localizedDescription)")
        }
    }
    
    private func exportAsJSON(_ bookmarks: [URLBookmark]) -> ExportResult {
        let exportData = ExportData(
            version: "1.0",
            exportDate: Date(),
            platform: getCurrentPlatform(),
            bookmarks: bookmarks.map { bookmark in
                BookmarkExportData(
                    id: bookmark.id.uuidString,
                    url: bookmark.url,
                    title: bookmark.title,
                    notes: bookmark.notes,
                    createdAt: bookmark.createdAt,
                    modifiedAt: bookmark.modifiedAt,
                    tags: [], // Future feature
                    metadata: BookmarkMetadata(
                        domain: extractDomain(from: bookmark.url),
                        isSecure: bookmark.url.hasPrefix("https://")
                    )
                )
            }
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(exportData)
            let filename = "url-bookmarks-\(dateFormatter.string(from: Date())).json"
            
            return .success(jsonData, filename, .json)
        } catch {
            return .failure("Failed to encode JSON: \(error.localizedDescription)")
        }
    }
    
    private func exportAsCSV(_ bookmarks: [URLBookmark]) -> ExportResult {
        var csvContent = "URL,Title,Notes,Created,Modified\n"
        
        for bookmark in bookmarks {
            let title = escapeCSV(bookmark.title ?? "")
            let notes = escapeCSV(bookmark.notes ?? "")
            let created = dateFormatter.string(from: bookmark.createdAt)
            let modified = dateFormatter.string(from: bookmark.modifiedAt)
            
            csvContent += "\"\(bookmark.url)\",\"\(title)\",\"\(notes)\",\"\(created)\",\"\(modified)\"\n"
        }
        
        let csvData = csvContent.data(using: .utf8)!
        let filename = "url-bookmarks-\(dateFormatter.string(from: Date())).csv"
        
        return .success(csvData, filename, .csv)
    }
    
    private func exportAsHTML(_ bookmarks: [URLBookmark]) -> ExportResult {
        var htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>URL Bookmarks Export</title>
            <meta charset="utf-8">
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
                .bookmark { margin: 16px 0; padding: 12px; border-left: 3px solid #007aff; }
                .title { font-weight: 600; margin-bottom: 4px; }
                .url { color: #007aff; text-decoration: none; }
                .notes { color: #666; font-size: 14px; margin-top: 8px; }
                .date { color: #999; font-size: 12px; }
            </style>
        </head>
        <body>
            <h1>URL Bookmarks</h1>
            <p>Exported on \(DateFormatter.readable.string(from: Date()))</p>
        """
        
        for bookmark in bookmarks {
            htmlContent += """
            <div class="bookmark">
                <div class="title">\(htmlEscape(bookmark.title ?? bookmark.url))</div>
                <a href="\(bookmark.url)" class="url">\(bookmark.url)</a>
            """
            
            if let notes = bookmark.notes, !notes.isEmpty {
                htmlContent += "<div class=\"notes\">\(htmlEscape(notes))</div>"
            }
            
            htmlContent += "<div class=\"date\">Added: \(DateFormatter.readable.string(from: bookmark.createdAt))</div>"
            htmlContent += "</div>"
        }
        
        htmlContent += "</body></html>"
        
        let htmlData = htmlContent.data(using: .utf8)!
        let filename = "url-bookmarks-\(dateFormatter.string(from: Date())).html"
        
        return .success(htmlData, filename, .html)
    }
    
    // MARK: - Import Functionality
    
    func importBookmarks(from data: Data, format: ExportFormat) -> ImportResult {
        switch format {
        case .json:
            return importFromJSON(data)
        case .csv:
            return importFromCSV(data)
        case .html:
            return importFromHTML(data)
        }
    }
    
    private func importFromJSON(_ data: Data) -> ImportResult {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Try new format first
            if let exportData = try? decoder.decode(ExportData.self, from: data) {
                return processImportData(exportData.bookmarks, source: "JSON Export v\(exportData.version)")
            }
            
            // Fallback to simple array format
            if let bookmarks = try? decoder.decode([BookmarkExportData].self, from: data) {
                return processImportData(bookmarks, source: "JSON Export (Legacy)")
            }
            
            // Fallback to basic format
            if let basicBookmarks = try? decoder.decode([[String: Any]].self, from: data) {
                let bookmarks = basicBookmarks.compactMap { dict -> BookmarkExportData? in
                    guard let url = dict["url"] as? String else { return nil }
                    
                    return BookmarkExportData(
                        id: UUID().uuidString,
                        url: url,
                        title: dict["title"] as? String,
                        notes: dict["notes"] as? String,
                        createdAt: parseDate(dict["createdAt"]) ?? Date(),
                        modifiedAt: parseDate(dict["modifiedAt"]) ?? Date(),
                        tags: [],
                        metadata: BookmarkMetadata(
                            domain: extractDomain(from: url),
                            isSecure: url.hasPrefix("https://")
                        )
                    )
                }
                
                return processImportData(bookmarks, source: "JSON Export (Basic)")
            }
            
            return .failure("Invalid JSON format")
            
        } catch {
            return .failure("Failed to parse JSON: \(error.localizedDescription)")
        }
    }
    
    private func importFromCSV(_ data: Data) -> ImportResult {
        guard let csvString = String(data: data, encoding: .utf8) else {
            return .failure("Invalid CSV encoding")
        }
        
        let lines = csvString.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            return .failure("Empty CSV file")
        }
        
        var bookmarks: [BookmarkExportData] = []
        
        // Skip header row
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count >= 2 else { continue }
            
            let url = fields[0]
            let title = fields.count > 1 ? (fields[1].isEmpty ? nil : fields[1]) : nil
            let notes = fields.count > 2 ? (fields[2].isEmpty ? nil : fields[2]) : nil
            
            bookmarks.append(BookmarkExportData(
                id: UUID().uuidString,
                url: url,
                title: title,
                notes: notes,
                createdAt: Date(),
                modifiedAt: Date(),
                tags: [],
                metadata: BookmarkMetadata(
                    domain: extractDomain(from: url),
                    isSecure: url.hasPrefix("https://")
                )
            ))
        }
        
        return processImportData(bookmarks, source: "CSV Import")
    }
    
    private func importFromHTML(_ data: Data) -> ImportResult {
        guard let htmlString = String(data: data, encoding: .utf8) else {
            return .failure("Invalid HTML encoding")
        }
        
        // Simple regex-based HTML parsing for bookmarks
        let linkPattern = #"<a\s+href="([^"]+)"[^>]*>([^<]+)</a>"#
        let regex = try! NSRegularExpression(pattern: linkPattern, options: .caseInsensitive)
        let matches = regex.matches(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString))
        
        var bookmarks: [BookmarkExportData] = []
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            
            let urlRange = Range(match.range(at: 1), in: htmlString)!
            let titleRange = Range(match.range(at: 2), in: htmlString)!
            
            let url = String(htmlString[urlRange])
            let title = String(htmlString[titleRange])
            
            bookmarks.append(BookmarkExportData(
                id: UUID().uuidString,
                url: url,
                title: title.isEmpty ? nil : title,
                notes: nil,
                createdAt: Date(),
                modifiedAt: Date(),
                tags: [],
                metadata: BookmarkMetadata(
                    domain: extractDomain(from: url),
                    isSecure: url.hasPrefix("https://")
                )
            ))
        }
        
        return processImportData(bookmarks, source: "HTML Import")
    }
    
    private func processImportData(_ bookmarks: [BookmarkExportData], source: String) -> ImportResult {
        var imported = 0
        var skipped = 0
        var errors: [String] = []
        
        for bookmarkData in bookmarks {
            // Validate URL
            guard URL(string: bookmarkData.url) != nil else {
                errors.append("Invalid URL: \(bookmarkData.url)")
                continue
            }
            
            // Check for duplicates
            if isDuplicate(url: bookmarkData.url) {
                skipped += 1
                continue
            }
            
            // Import bookmark
            if let _ = persistenceController.addURL(
                bookmarkData.url,
                title: bookmarkData.title,
                notes: bookmarkData.notes
            ) {
                imported += 1
            } else {
                errors.append("Failed to import: \(bookmarkData.url)")
            }
        }
        
        let summary = ImportSummary(
            source: source,
            totalItems: bookmarks.count,
            imported: imported,
            skipped: skipped,
            errors: errors
        )
        
        return .success(summary)
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflicts(_ conflicts: [BookmarkConflict]) -> ConflictResolutionResult {
        var resolved = 0
        var failed = 0
        
        for conflict in conflicts {
            switch conflict.resolution {
            case .keepLocal:
                // Keep local version, no action needed
                resolved += 1
                
            case .keepRemote:
                // Update local with remote version
                if updateLocalBookmark(conflict.local, with: conflict.remote) {
                    resolved += 1
                } else {
                    failed += 1
                }
                
            case .merge:
                // Merge both versions
                if mergeBookmarks(conflict.local, conflict.remote) {
                    resolved += 1
                } else {
                    failed += 1
                }
            }
        }
        
        return ConflictResolutionResult(resolved: resolved, failed: failed)
    }
    
    private func updateLocalBookmark(_ local: URLBookmark, with remote: BookmarkExportData) -> Bool {
        local.title = remote.title
        local.notes = remote.notes
        local.modifiedAt = remote.modifiedAt
        
        persistenceController.save()
        return true
    }
    
    private func mergeBookmarks(_ local: URLBookmark, _ remote: BookmarkExportData) -> Bool {
        // Use most recent title if different
        if let remoteTitle = remote.title, remoteTitle != local.title {
            local.title = remote.modifiedAt > local.modifiedAt ? remoteTitle : local.title
        }
        
        // Merge notes
        let localNotes = local.notes ?? ""
        let remoteNotes = remote.notes ?? ""
        
        if !localNotes.isEmpty && !remoteNotes.isEmpty && localNotes != remoteNotes {
            local.notes = "\(localNotes)\n\n---\n\(remoteNotes)"
        } else if !remoteNotes.isEmpty {
            local.notes = remoteNotes
        }
        
        // Use most recent modification date
        local.modifiedAt = max(local.modifiedAt, remote.modifiedAt)
        
        persistenceController.save()
        return true
    }
    
    // MARK: - Utility Methods
    
    private func isDuplicate(url: String) -> Bool {
        let fetchRequest = URLBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "url == %@ AND isDeleted == NO", url)
        
        do {
            let count = try persistenceController.context.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
    
    private func getCurrentPlatform() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Unknown"
        #endif
    }
    
    private func extractDomain(from url: String) -> String {
        guard let urlObj = URL(string: url) else { return "" }
        return urlObj.host ?? ""
    }
    
    private func escapeCSV(_ string: String) -> String {
        return string.replacingOccurrences(of: "\"", with: "\"\"")
    }
    
    private func htmlEscape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                if inQuotes && i < line.index(before: line.endIndex) && line[line.index(after: i)] == "\"" {
                    currentField += "\""
                    i = line.index(after: i)
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField += String(char)
            }
            
            i = line.index(after: i)
        }
        
        fields.append(currentField)
        return fields
    }
    
    private func parseDate(_ value: Any?) -> Date? {
        if let dateString = value as? String {
            return ISO8601DateFormatter().date(from: dateString) ?? 
                   DateFormatter.readable.date(from: dateString)
        }
        return value as? Date
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
}

// MARK: - Data Models

struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let platform: String
    let bookmarks: [BookmarkExportData]
}

struct BookmarkExportData: Codable {
    let id: String
    let url: String
    let title: String?
    let notes: String?
    let createdAt: Date
    let modifiedAt: Date
    let tags: [String]
    let metadata: BookmarkMetadata
}

struct BookmarkMetadata: Codable {
    let domain: String
    let isSecure: Bool
}

enum ExportFormat {
    case json, csv, html
}

enum ExportResult {
    case success(Data, String, ExportFormat)
    case failure(String)
}

enum ImportResult {
    case success(ImportSummary)
    case failure(String)
}

struct ImportSummary {
    let source: String
    let totalItems: Int
    let imported: Int
    let skipped: Int
    let errors: [String]
}

struct BookmarkConflict {
    let local: URLBookmark
    let remote: BookmarkExportData
    let resolution: ConflictResolution
}

enum ConflictResolution {
    case keepLocal, keepRemote, merge
}

struct ConflictResolutionResult {
    let resolved: Int
    let failed: Int
}

extension DateFormatter {
    static let readable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
