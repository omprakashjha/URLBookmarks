import SwiftUI

struct AddURLView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var persistenceController: PersistenceController
    
    @State private var url = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var isValidURL = true
    @FocusState private var isURLFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isURLFieldFocused)
                        .onSubmit {
                            validateAndFetchTitle()
                        }
                    
                    if !isValidURL {
                        Text("Please enter a valid URL")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("URL")
                }
                
                Section {
                    TextField("Website title", text: $title)
                } header: {
                    Text("Title (Optional)")
                }
                
                Section {
                    TextField("Add notes about this URL", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                }
            }
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addBookmark()
                    }
                    .fontWeight(.semibold)
                    .disabled(url.isEmpty || !isValidURL)
                }
            }
            .onAppear {
                isURLFieldFocused = true
                checkClipboard()
            }
        }
    }
    
    private func checkClipboard() {
        if let clipboardString = UIPasteboard.general.string,
           URL(string: clipboardString) != nil {
            url = clipboardString
            validateAndFetchTitle()
        }
    }
    
    private func validateAndFetchTitle() {
        isValidURL = URL(string: url) != nil
        
        if isValidURL && title.isEmpty {
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
