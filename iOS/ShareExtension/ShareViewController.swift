import SwiftUI
import Social
import UniformTypeIdentifiers

struct ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostingController = UIHostingController(rootView: ShareExtensionView(
            onSave: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: NSError(domain: "ShareExtension", code: 0))
            }
        ))
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
}

struct ShareExtensionView: View {
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var url = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("URL", text: $url)
                        .disabled(true)
                } header: {
                    Text("URL")
                }
                
                Section {
                    TextField("Title", text: $title)
                } header: {
                    Text("Title")
                }
                
                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                }
            }
            .navigationTitle("Save Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBookmark()
                    }
                    .disabled(url.isEmpty)
                }
            }
        }
        .onAppear {
            loadSharedContent()
        }
    }
    
    private func loadSharedContent() {
        guard let extensionContext = (UIApplication.shared.delegate as? ShareViewController)?.extensionContext else {
            return
        }
        
        for item in extensionContext.inputItems {
            guard let inputItem = item as? NSExtensionItem else { continue }
            
            for provider in inputItem.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { (item, error) in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self.url = url.absoluteString
                                self.title = url.host?.replacingOccurrences(of: "www.", with: "") ?? ""
                            }
                            self.isLoading = false
                        }
                    }
                    return
                }
            }
        }
        
        isLoading = false
    }
    
    private func saveBookmark() {
        let persistenceController = PersistenceController.shared
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        _ = persistenceController.addURL(
            url,
            title: trimmedTitle.isEmpty ? nil : trimmedTitle,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        
        onSave()
    }
}
