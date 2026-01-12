import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var persistenceController: PersistenceController
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \URLBookmark.modifiedAt, ascending: false)],
        predicate: NSPredicate(format: "isDeleted == NO"),
        animation: .default)
    private var bookmarks: FetchedResults<URLBookmark>
    
    @State private var searchText = ""
    @State private var showingAddURL = false
    @State private var selectedBookmark: URLBookmark?
    
    var filteredBookmarks: [URLBookmark] {
        if searchText.isEmpty {
            return Array(bookmarks)
        } else {
            return persistenceController.searchBookmarks(searchText)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search URLs...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .padding()
                
                // URL List
                List(filteredBookmarks, id: \.id, selection: $selectedBookmark) { bookmark in
                    URLBookmarkRow(bookmark: bookmark)
                        .contextMenu {
                            Button("Open URL") {
                                openURL(bookmark.url)
                            }
                            Button("Copy URL") {
                                copyToClipboard(bookmark.url)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteBookmark(bookmark)
                            }
                        }
                }
                .listStyle(.sidebar)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddURL = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .status) {
                    SyncStatusView()
                }
            }
        } detail: {
            if let selectedBookmark = selectedBookmark {
                URLDetailView(bookmark: selectedBookmark)
            } else {
                Text("Select a URL to view details")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingAddURL) {
            AddURLView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddURL)) { _ in
            showingAddURL = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            // Focus search field (implementation depends on macOS version)
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportURLs)) { _ in
            exportURLs()
        }
        .onReceive(NotificationCenter.default.publisher(for: .importURLs)) { _ in
            importURLs()
        }
    }
    
    // MARK: - Actions
    private func deleteBookmark(_ bookmark: URLBookmark) {
        persistenceController.deleteBookmark(bookmark)
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    private func exportURLs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "URL Bookmarks.json"
        
        if panel.runModal() == .OK, let url = panel.url {
            exportBookmarks(to: url)
        }
    }
    
    private func importURLs() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            importBookmarks(from: url)
        }
    }
    
    private func exportBookmarks(to url: URL) {
        let bookmarksData = bookmarks.map { bookmark in
            [
                "url": bookmark.url,
                "title": bookmark.title ?? "",
                "notes": bookmark.notes ?? "",
                "createdAt": ISO8601DateFormatter().string(from: bookmark.createdAt),
                "modifiedAt": ISO8601DateFormatter().string(from: bookmark.modifiedAt)
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: bookmarksData, options: .prettyPrinted)
            try jsonData.write(to: url)
        } catch {
            print("Export error: \(error)")
        }
    }
    
    private func importBookmarks(from url: URL) {
        do {
            let jsonData = try Data(contentsOf: url)
            let bookmarksArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] ?? []
            
            for bookmarkData in bookmarksArray {
                if let urlString = bookmarkData["url"] as? String {
                    let title = bookmarkData["title"] as? String
                    let notes = bookmarkData["notes"] as? String
                    _ = persistenceController.addURL(urlString, title: title, notes: notes)
                }
            }
        } catch {
            print("Import error: \(error)")
        }
    }
}
