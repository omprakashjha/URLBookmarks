import SwiftUI

struct URLBookmarkRow: View {
    let bookmark: URLBookmark
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Favicon placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Text(String(bookmark.url.prefix(1).uppercased()))
                            .font(.caption2)
                            .fontWeight(.medium)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(bookmark.title ?? bookmark.url)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    
                    Text(bookmark.url)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(RelativeDateTimeFormatter().localizedString(for: bookmark.modifiedAt, relativeTo: Date()))
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
            
            if let notes = bookmark.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let context = PersistenceController.shared.context
    let bookmark = URLBookmark(context: context, url: "https://example.com", title: "Example Website", notes: "A sample website for testing")
    
    return URLBookmarkRow(bookmark: bookmark)
        .padding()
}
