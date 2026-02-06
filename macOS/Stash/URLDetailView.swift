import SwiftUI

struct URLDetailView: View {
    @ObservedObject var bookmark: URLBookmark
    @EnvironmentObject private var persistenceController: PersistenceController
    
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editNotes = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String((bookmark.url ?? "U").prefix(1).uppercased()))
                                    .font(.title3)
                                    .fontWeight(.medium)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if isEditing {
                                TextField("Title", text: $editTitle)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.title2)
                            } else {
                                Text(bookmark.title ?? "Untitled")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(bookmark.url ?? "")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    openURL()
                                }
                        }
                        
                        Spacer()
                        
                        Button(isEditing ? "Done" : "Edit") {
                            if isEditing {
                                saveChanges()
                            } else {
                                startEditing()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Divider()
                
                // URL Actions
                HStack(spacing: 12) {
                    Button("Open URL") {
                        openURL()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Copy URL") {
                        copyURL()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Share") {
                        shareURL()
                    }
                    .buttonStyle(.bordered)
                }
                
                // Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    if isEditing {
                        TextField("Add notes about this URL", text: $editNotes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(5...10)
                    } else {
                        if let notes = bookmark.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.body)
                                .textSelection(.enabled)
                        } else {
                            Text("No notes")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    HStack {
                        Text("Created:")
                        Spacer()
                        if let createdAt = bookmark.createdAt {
                            Text(createdAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Modified:")
                        Spacer()
                        if let modifiedAt = bookmark.modifiedAt {
                            Text(modifiedAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .font(.subheadline)
                
                Spacer()
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func startEditing() {
        editTitle = bookmark.title ?? ""
        editNotes = bookmark.notes ?? ""
        isEditing = true
    }
    
    private func saveChanges() {
        bookmark.title = editTitle.isEmpty ? nil : editTitle
        bookmark.notes = editNotes.isEmpty ? nil : editNotes
        bookmark.updateModifiedDate()
        persistenceController.save()
        isEditing = false
    }
    
    private func openURL() {
        if let urlString = bookmark.url, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func copyURL() {
        if let urlString = bookmark.url {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(urlString, forType: .string)
        }
    }
    
    private func shareURL() {
        if let urlString = bookmark.url {
            let sharingService = NSSharingService(named: .composeMessage)
            sharingService?.perform(withItems: [urlString])
        }
    }
}

#Preview {
    let context = PersistenceController.shared.context
    let bookmark = URLBookmark(context: context, url: "https://example.com", title: "Example Website", notes: "A sample website for testing purposes")
    
    return URLDetailView(bookmark: bookmark)
        .environmentObject(PersistenceController.shared)
}
