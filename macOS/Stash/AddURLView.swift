import SwiftUI

struct AddURLView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var persistenceController: PersistenceController
    
    @State private var url = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var isValidURL = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add URL Bookmark")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("URL")
                    .font(.headline)
                TextField("https://example.com", text: $url)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        validateAndFetchTitle()
                    }
                
                if !isValidURL {
                    Text("Please enter a valid URL")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Title (Optional)")
                    .font(.headline)
                TextField("Website title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.headline)
                TextField("Add notes about this URL", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Add Bookmark") {
                    addBookmark()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty || !isValidURL)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            // Check if URL is in clipboard
            if let clipboardString = NSPasteboard.general.string(forType: .string),
               URL(string: clipboardString) != nil {
                url = clipboardString
                validateAndFetchTitle()
            }
        }
    }
    
    private func validateAndFetchTitle() {
        isValidURL = URL(string: url) != nil
        
        if isValidURL && title.isEmpty {
            // In a real app, you might fetch the page title here
            // For now, we'll extract domain as title
            if let urlObj = URL(string: url) {
                title = urlObj.host ?? ""
            }
        }
    }
    
    private func addBookmark() {
        guard isValidURL else { return }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        _ = persistenceController.addURL(
            url,
            title: trimmedTitle.isEmpty ? nil : trimmedTitle,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        
        dismiss()
    }
}

#Preview {
    AddURLView()
        .environmentObject(PersistenceController.shared)
}
