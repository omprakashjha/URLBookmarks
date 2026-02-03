import SwiftUI

struct BackupManagerView: View {
    @StateObject private var syncManager = CrossPlatformSyncManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var backups: [BackupInfo] = []
    @State private var isCreatingBackup = false
    @State private var showingRestorePicker = false
    @State private var showingMigrationPicker = false
    @State private var backupToShare: (BackupInfo, Data)?
    
    var body: some View {
        NavigationStack {
            List {
                // Create Backup Section
                Section {
                    Button {
                        createBackup()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Create New Backup")
                                    .fontWeight(.medium)
                                Text("Save current bookmarks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if isCreatingBackup {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isCreatingBackup)
                } header: {
                    Text("Backup")
                }
                
                // Restore Section
                Section {
                    Button {
                        showingRestorePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Restore from File")
                                    .fontWeight(.medium)
                                Text("Import bookmarks from backup file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        showingMigrationPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Migrate from Browser")
                                    .fontWeight(.medium)
                                Text("Import from Safari, Chrome, or Firefox")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Restore")
                }
                
                // Available Backups
                if !backups.isEmpty {
                    Section {
                        ForEach(backups.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { backup in
                            BackupRowView(backup: backup) {
                                shareBackup(backup)
                            }
                        }
                    } header: {
                        Text("Available Backups")
                    } footer: {
                        Text("Tap a backup to share it. Only the 10 most recent backups are kept.")
                    }
                }
            }
            .navigationTitle("Backup Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadBackups()
        }
        .fileImporter(
            isPresented: $showingRestorePicker,
            allowedContentTypes: [.json, .commaSeparatedText, .html],
            allowsMultipleSelection: false
        ) { result in
            handleRestore(result: result)
        }
        .fileImporter(
            isPresented: $showingMigrationPicker,
            allowedContentTypes: [.json, .html, .propertyList],
            allowsMultipleSelection: false
        ) { result in
            handleMigration(result: result)
        }
        .sheet(item: Binding<BackupShareItem?>(
            get: { backupToShare.map { BackupShareItem(backup: $0.0, data: $0.1) } },
            set: { _ in backupToShare = nil }
        )) { item in
            ShareSheet(items: [item.data])
        }
    }
    
    private func createBackup() {
        isCreatingBackup = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = syncManager.createBackup()
            
            DispatchQueue.main.async {
                self.isCreatingBackup = false
                
                switch result {
                case .success(let backup, let data):
                    self.backups.append(backup)
                    self.backupToShare = (backup, data)
                    
                case .failure(let error):
                    print("Backup creation failed: \(error)")
                }
            }
        }
    }
    
    private func shareBackup(_ backup: BackupInfo) {
        // Load backup data and share
        // In a real implementation, you would load the backup data from storage
        let result = syncManager.createBackup()
        
        switch result {
        case .success(_, let data):
            backupToShare = (backup, data)
        case .failure(let error):
            print("Failed to load backup: \(error)")
        }
    }
    
    private func loadBackups() {
        backups = syncManager.getAvailableBackups()
    }
    
    private func handleRestore(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let restoreResult = syncManager.restoreFromBackup(data)
                
                switch restoreResult {
                case .success(let summary):
                    print("Restore successful: \(summary.imported) imported, \(summary.skipped) skipped")
                case .failure(let error):
                    print("Restore failed: \(error)")
                }
                
            } catch {
                print("Restore error: \(error)")
            }
            
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
    
    private func handleMigration(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let migrationResult = syncManager.migrateFromLegacyFormat(data)
                
                switch migrationResult {
                case .success(let summary):
                    print("Migration successful: \(summary.imported) imported from \(summary.source)")
                case .failure(let error):
                    print("Migration failed: \(error)")
                }
                
            } catch {
                print("Migration error: \(error)")
            }
            
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
}

struct BackupRowView: View {
    let backup: BackupInfo
    let onShare: () -> Void
    
    var body: some View {
        Button(action: onShare) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.filename)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("\(backup.bookmarkCount) bookmarks")
                        Text("•")
                        Text(formatFileSize(backup.size))
                        Text("•")
                        Text(backup.platform)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text(formatDate(backup.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct BackupShareItem: Identifiable {
    let id = UUID()
    let backup: BackupInfo
    let data: Data
}

#Preview {
    BackupManagerView()
}
