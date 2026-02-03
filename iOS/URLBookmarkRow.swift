import SwiftUI

struct URLBookmarkRow: View {
    let bookmark: URLBookmark
    
    var body: some View {
        HStack(spacing: 12) {
            // Favicon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String((bookmark.url ?? "U").prefix(1).uppercased()))
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title ?? bookmark.url ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)
                
                Text(bookmark.url ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let notes = bookmark.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let modifiedAt = bookmark.modifiedAt {
                    Text(RelativeDateTimeFormatter().localizedString(for: modifiedAt, relativeTo: Date()))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let context = PersistenceController.shared.context
    let bookmark = URLBookmark(context: context, url: "https://example.com", title: "Example Website", notes: "A sample website for testing")
    
    return URLBookmarkRow(bookmark: bookmark)
        .padding()
}
