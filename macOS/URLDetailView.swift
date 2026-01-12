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
                                Text(String(bookmark.url.prefix(1).uppercased()))
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
                            
                            Text(bookmark.url)
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
                        Text(bookmark.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Modified:")
                        Spacer()
                        Text(bookmark.modifiedAt, style: .date)
                            .foregroundColor(.secondary)
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
        if let url = URL(string: bookmark.url) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(bookmark.url, forType: .string)
    }
    
    private func shareURL() {
        let sharingService = NSSharingService(named: .composeMessage)
        sharingService?.perform(withItems: [bookmark.url])
    }
}

#Preview {
    let context = PersistenceController.shared.context
    let bookmark = URLBookmark(context: context, url: "https://example.com", title: "Example Website", notes: "A sample website for testing purposes")
    
    return URLDetailView(bookmark: bookmark)
        .environmentObject(PersistenceController.shared)
}
