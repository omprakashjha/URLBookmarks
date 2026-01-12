import WidgetKit
import SwiftUI
import CoreData

struct BookmarkWidget: Widget {
    let kind: String = "BookmarkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookmarkProvider()) { entry in
            BookmarkWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Recent Bookmarks")
        .description("View your most recent URL bookmarks")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct BookmarkEntry: TimelineEntry {
    let date: Date
    let bookmarks: [BookmarkData]
}

struct BookmarkData {
    let id: UUID
    let url: String
    let title: String
    let createdAt: Date
}

struct BookmarkProvider: TimelineProvider {
    func placeholder(in context: Context) -> BookmarkEntry {
        BookmarkEntry(date: Date(), bookmarks: [
            BookmarkData(id: UUID(), url: "https://example.com", title: "Example Website", createdAt: Date())
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (BookmarkEntry) -> ()) {
        let entry = BookmarkEntry(date: Date(), bookmarks: fetchRecentBookmarks())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookmarkEntry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        
        let entry = BookmarkEntry(date: currentDate, bookmarks: fetchRecentBookmarks())
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
    
    private func fetchRecentBookmarks() -> [BookmarkData] {
        let persistenceController = PersistenceController.shared
        let fetchRequest = URLBookmark.activeFetchRequest()
        fetchRequest.fetchLimit = 10
        
        do {
            let bookmarks = try persistenceController.context.fetch(fetchRequest)
            return bookmarks.map { bookmark in
                BookmarkData(
                    id: bookmark.id,
                    url: bookmark.url,
                    title: bookmark.title ?? bookmark.url,
                    createdAt: bookmark.createdAt
                )
            }
        } catch {
            print("Widget fetch error: \(error)")
            return []
        }
    }
}

struct BookmarkWidgetEntryView: View {
    var entry: BookmarkProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallBookmarkWidget(bookmarks: entry.bookmarks)
        case .systemMedium:
            MediumBookmarkWidget(bookmarks: entry.bookmarks)
        case .systemLarge:
            LargeBookmarkWidget(bookmarks: entry.bookmarks)
        default:
            SmallBookmarkWidget(bookmarks: entry.bookmarks)
        }
    }
}

struct SmallBookmarkWidget: View {
    let bookmarks: [BookmarkData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.blue)
                Text("Bookmarks")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let bookmark = bookmarks.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Text(bookmark.url)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .widgetURL(URL(string: bookmark.url))
            } else {
                Text("No bookmarks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct MediumBookmarkWidget: View {
    let bookmarks: [BookmarkData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.blue)
                Text("Recent Bookmarks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if bookmarks.isEmpty {
                Text("No bookmarks yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ForEach(bookmarks.prefix(3), id: \.id) { bookmark in
                    Link(destination: URL(string: bookmark.url)!) {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(String(bookmark.url.prefix(1).uppercased()))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bookmark.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text(bookmark.url)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct LargeBookmarkWidget: View {
    let bookmarks: [BookmarkData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.blue)
                Text("Recent Bookmarks")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if bookmarks.isEmpty {
                VStack {
                    Image(systemName: "link.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No bookmarks yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(bookmarks.prefix(6), id: \.id) { bookmark in
                        Link(destination: URL(string: bookmark.url)!) {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(bookmark.url.prefix(1).uppercased()))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bookmark.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    
                                    Text(bookmark.url)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    Text(RelativeDateTimeFormatter().localizedString(for: bookmark.createdAt, relativeTo: Date()))
                                        .font(.caption2)
                                        .foregroundColor(.tertiary)
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview("Small", as: .systemSmall) {
    BookmarkWidget()
} timeline: {
    BookmarkEntry(date: Date(), bookmarks: [
        BookmarkData(id: UUID(), url: "https://example.com", title: "Example Website", createdAt: Date())
    ])
}
