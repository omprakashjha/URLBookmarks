import SwiftUI

struct ConflictResolutionView: View {
    let conflicts: [BookmarkConflict]
    let onResolve: ([String: ConflictResolution]) -> Void
    
    @State private var resolutions: [String: ConflictResolution] = [:]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sync Conflicts Detected")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("The following bookmarks have been modified on multiple devices. Choose how to resolve each conflict:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Conflicts List
                List {
                    ForEach(Array(conflicts.enumerated()), id: \.offset) { index, conflict in
                        ConflictRowView(
                            conflict: conflict,
                            resolution: resolutions[conflict.local.id.uuidString] ?? .merge
                        ) { newResolution in
                            resolutions[conflict.local.id.uuidString] = newResolution
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button("Keep All Local") {
                            resolveAll(with: .keepLocal)
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Keep All Remote") {
                            resolveAll(with: .keepRemote)
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Merge All") {
                            resolveAll(with: .merge)
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button("Apply Resolutions") {
                        applyResolutions()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(resolutions.count != conflicts.count)
                }
                .padding()
            }
            .navigationTitle("Resolve Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Initialize with default merge resolution
            for conflict in conflicts {
                resolutions[conflict.local.id.uuidString] = .merge
            }
        }
    }
    
    private func resolveAll(with resolution: ConflictResolution) {
        for conflict in conflicts {
            resolutions[conflict.local.id.uuidString] = resolution
        }
    }
    
    private func applyResolutions() {
        onResolve(resolutions)
        dismiss()
    }
}

struct ConflictRowView: View {
    let conflict: BookmarkConflict
    let resolution: ConflictResolution
    let onResolutionChange: (ConflictResolution) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // URL Header
            Text(conflict.local.url)
                .font(.headline)
                .foregroundColor(.blue)
            
            // Local vs Remote Comparison
            HStack(alignment: .top, spacing: 16) {
                // Local Version
                VStack(alignment: .leading, spacing: 8) {
                    Text("Local Version")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title: \(conflict.local.title ?? "No title")")
                            .font(.caption)
                        
                        if let notes = conflict.local.notes {
                            Text("Notes: \(notes)")
                                .font(.caption)
                                .lineLimit(2)
                        }
                        
                        Text("Modified: \(formatDate(conflict.local.modifiedAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Remote Version
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remote Version")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title: \(conflict.remote.title ?? "No title")")
                            .font(.caption)
                        
                        if let notes = conflict.remote.notes {
                            Text("Notes: \(notes)")
                                .font(.caption)
                                .lineLimit(2)
                        }
                        
                        Text("Modified: \(formatDate(conflict.remote.modifiedAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Resolution Picker
            Picker("Resolution", selection: Binding(
                get: { resolution },
                set: { onResolutionChange($0) }
            )) {
                Text("Keep Local").tag(ConflictResolution.keepLocal)
                Text("Keep Remote").tag(ConflictResolution.keepRemote)
                Text("Merge Both").tag(ConflictResolution.merge)
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let sampleConflict = BookmarkConflict(
        local: {
            let context = PersistenceController.shared.context
            return URLBookmark(context: context, url: "https://example.com", title: "Local Title", notes: "Local notes")
        }(),
        remote: BookmarkExportData(
            id: UUID().uuidString,
            url: "https://example.com",
            title: "Remote Title",
            notes: "Remote notes",
            createdAt: Date(),
            modifiedAt: Date(),
            tags: [],
            metadata: BookmarkMetadata(domain: "example.com", isSecure: true)
        ),
        resolution: .merge
    )
    
    return ConflictResolutionView(conflicts: [sampleConflict]) { _ in }
}
