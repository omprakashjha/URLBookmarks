import SwiftUI
import SafariServices

struct URLDetailView: View {
    @ObservedObject var bookmark: URLBookmark
    @EnvironmentObject private var persistenceController: PersistenceController
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editNotes = ""
    @State private var showingSafari = false
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String((bookmark.url ?? "U").prefix(1).uppercased()))
                                    .font(.title)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if isEditing {
                                TextField("Title", text: $editTitle)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            } else {
                                Text(bookmark.title ?? "Untitled")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(bookmark.url ?? "")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Open") {
                        showingSafari = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Share") {
                        showingShareSheet = true
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Copy") {
                        UIPasteboard.general.string = bookmark.url
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
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
                        } else {
                            Text("No notes")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    if let createdAt = bookmark.createdAt {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(createdAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let modifiedAt = bookmark.modifiedAt {
                        HStack {
                            Text("Modified")
                            Spacer()
                            Text(modifiedAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("Bookmark")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingSafari) {
            if let urlString = bookmark.url, let url = URL(string: urlString) {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let urlString = bookmark.url {
                ShareSheet(items: [urlString])
            }
        }
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
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let context = PersistenceController.shared.context
    let bookmark = URLBookmark(context: context, url: "https://example.com", title: "Example Website", notes: "A sample website for testing")
    
    return NavigationStack {
        URLDetailView(bookmark: bookmark)
            .environmentObject(PersistenceController.shared)
    }
}
