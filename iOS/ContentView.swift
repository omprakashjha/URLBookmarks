import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var persistenceController: PersistenceController
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var performanceManager = PerformanceManager.shared
    
    @State private var searchText = ""
    @State private var showingAddURL = false
    @State private var showingSettings = false
    @State private var selectedBookmark: URLBookmark?
    @State private var isSearching = false
    @State private var searchResults: [URLBookmark] = []
    @State private var showingOfflineIndicator = false
    
    // Virtual scrolling state
    @State private var displayedBookmarks: [URLBookmark] = []
    @State private var isLoadingMore = false
    @State private var hasMoreBookmarks = true
    private let batchSize = 20
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Offline indicator
                if !offlineManager.isOnline {
                    OfflineIndicatorView()
                        .transition(.move(edge: .top))
                }
                
                // Search bar
                SearchBarView(
                    searchText: $searchText,
                    isSearching: $isSearching,
                    onSearchChanged: handleSearchChange
                )
                
                // Content
                if displayedBookmarks.isEmpty && !isSearching {
                    EmptyStateView(searchText: searchText) {
                        showingAddURL = true
                    }
                } else {
                    VirtualScrollView(
                        bookmarks: displayedBookmarks,
                        isLoadingMore: isLoadingMore,
                        hasMoreBookmarks: hasMoreBookmarks,
                        onBookmarkTap: { bookmark in
                            selectedBookmark = bookmark
                        },
                        onDelete: deleteBookmark,
                        onLoadMore: loadMoreBookmarks
                    )
                }
            }
            .navigationTitle("URL Bookmarks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddURL = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddURL) {
                AddURLView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $selectedBookmark) { bookmark in
                URLDetailView(bookmark: bookmark)
            }
            .onAppear {
                loadInitialBookmarks()
            }
            .onChange(of: offlineManager.isOnline) { isOnline in
                withAnimation {
                    showingOfflineIndicator = !isOnline
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialBookmarks() {
        if searchText.isEmpty {
            displayedBookmarks = performanceManager.getBookmarksBatch(
                offset: 0,
                limit: batchSize,
                searchText: ""
            )
        } else {
            searchResults = performanceManager.performOptimizedSearch(searchText)
            displayedBookmarks = Array(searchResults.prefix(batchSize))
        }
        
        hasMoreBookmarks = displayedBookmarks.count == batchSize
    }
    
    private func loadMoreBookmarks() {
        guard !isLoadingMore && hasMoreBookmarks else { return }
        
        isLoadingMore = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let newBookmarks: [URLBookmark]
            
            if searchText.isEmpty {
                newBookmarks = performanceManager.getBookmarksBatch(
                    offset: displayedBookmarks.count,
                    limit: batchSize,
                    searchText: ""
                )
            } else {
                let startIndex = displayedBookmarks.count
                let endIndex = min(startIndex + batchSize, searchResults.count)
                newBookmarks = Array(searchResults[startIndex..<endIndex])
            }
            
            DispatchQueue.main.async {
                self.displayedBookmarks.append(contentsOf: newBookmarks)
                self.hasMoreBookmarks = newBookmarks.count == self.batchSize
                self.isLoadingMore = false
            }
        }
    }
    
    private func handleSearchChange() {
        isSearching = true
        
        // Debounce search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            performSearch()
        }
    }
    
    private func performSearch() {
        if searchText.isEmpty {
            loadInitialBookmarks()
        } else {
            searchResults = performanceManager.performOptimizedSearch(searchText)
            displayedBookmarks = Array(searchResults.prefix(batchSize))
            hasMoreBookmarks = searchResults.count > batchSize
        }
        
        isSearching = false
    }
    
    private func deleteBookmark(_ bookmark: URLBookmark) {
        if offlineManager.isOnline {
            persistenceController.deleteBookmark(bookmark)
        } else {
            // Queue for offline processing
            let operation = OfflineOperation(
                type: .deleteBookmark,
                data: ["id": bookmark.id.uuidString]
            )
            offlineManager.queueOperation(operation)
            
            // Remove from local display
            displayedBookmarks.removeAll { $0.id == bookmark.id }
        }
    }
}

// MARK: - Supporting Views

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let onSearchChanged: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search bookmarks...", text: $searchText)
                .textFieldStyle(.plain)
                .onChange(of: searchText) { _ in
                    onSearchChanged()
                }
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    onSearchChanged()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct OfflineIndicatorView: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
            Text("Offline - Changes will sync when connected")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.orange)
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

struct EmptyStateView: View {
    let searchText: String
    let onAddBookmark: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "link.circle" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No bookmarks yet" : "No results found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(searchText.isEmpty ? 
                 "Tap + to add your first URL bookmark" : 
                 "Try a different search term")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty {
                Button("Add URL") {
                    onAddBookmark()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct VirtualScrollView: View {
    let bookmarks: [URLBookmark]
    let isLoadingMore: Bool
    let hasMoreBookmarks: Bool
    let onBookmarkTap: (URLBookmark) -> Void
    let onDelete: (URLBookmark) -> Void
    let onLoadMore: () -> Void
    
    var body: some View {
        List {
            ForEach(bookmarks, id: \.id) { bookmark in
                URLBookmarkRow(bookmark: bookmark)
                    .onTapGesture {
                        onBookmarkTap(bookmark)
                    }
                    .onAppear {
                        // Load more when approaching end
                        if bookmark == bookmarks.last && hasMoreBookmarks {
                            onLoadMore()
                        }
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    onDelete(bookmarks[index])
                }
            }
            
            // Loading indicator
            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Refresh action
            onLoadMore()
        }
    }
}
