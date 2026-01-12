import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var persistenceController: PersistenceController
    @StateObject private var syncManager = CrossPlatformSyncManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingConflictResolution = false
    @State private var showingBackupManager = false
    @State private var exportURL: URL?
    @State private var selectedExportFormat: ExportFormat = .json

    var body: some View {
        NavigationStack {
            List {
                // Sync Section
                Section {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                                .font(.headline)
                            Text(persistenceController.isSyncEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $persistenceController.isSyncEnabled)
                    }
                    .padding(.vertical, 4)
                    
                    if persistenceController.isSyncEnabled {
                        HStack {
                            SyncStatusView()
                            
                            Spacer()
                            
                            Button("Sync Now") {
                                syncManager.startSync()
                            }
                            .font(.caption)
                            .disabled(syncManager.syncStatus == .syncing)
                        }
                        .padding(.vertical, 4)
                        
                        // Show conflicts if any
                        if case .conflictsDetected(let count) = syncManager.syncStatus {
                            Button {
                                showingConflictResolution = true
                            } label: {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("\(count) conflicts need resolution")
                                        .foregroundColor(.orange)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Synchronization")
                } footer: {
                    Text(persistenceController.isSyncEnabled ? 
                         "Your bookmarks sync across all devices signed in to the same iCloud account." :
                         "Enable iCloud sync to access bookmarks on all your devices.")
                }
                
                // Export/Import Section
                Section {
                    // Export Options
                    Menu {
                        Button("JSON Format") {
                            selectedExportFormat = .json
                            exportBookmarks()
                        }
                        Button("CSV Format") {
                            selectedExportFormat = .csv
                            exportBookmarks()
                        }
                        Button("HTML Format") {
                            selectedExportFormat = .html
                            exportBookmarks()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Export Bookmarks")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        showingImportPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Import Bookmarks")
                            Spacer()
                        }
                    }
                    
                    Button {
                        showingBackupManager = true
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Backup Manager")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Export your bookmarks for backup or transfer to another device. Import supports JSON, CSV, and HTML formats.")
                }
                
                // About Section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("URL Bookmarks")
                                .font(.headline)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if let lastSync = syncManager.lastSyncDate {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
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
        .sheet(isPresented: $showingExportSheet) {
            if let exportURL = exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json, .commaSeparatedText, .html],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .sheet(isPresented: $showingConflictResolution) {
            ConflictResolutionView(conflicts: syncManager.pendingConflicts) { resolutions in
                syncManager.resolveConflicts(with: resolutions)
                showingConflictResolution = false
            }
        }
        .sheet(isPresented: $showingBackupManager) {
            BackupManagerView()
        }
    }
    
    private func exportBookmarks() {
        let exportService = ExportImportService.shared
        let result = exportService.exportBookmarks(format: selectedExportFormat)
        
        switch result {
        case .success(let data, let filename, _):
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let exportPath = documentsPath.appendingPathComponent(filename)
            
            do {
                try data.write(to: exportPath)
                exportURL = exportPath
                showingExportSheet = true
            } catch {
                print("Export error: \(error)")
            }
            
        case .failure(let error):
            print("Export failed: \(error)")
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let format: ExportFormat
                
                switch url.pathExtension.lowercased() {
                case "csv":
                    format = .csv
                case "html", "htm":
                    format = .html
                default:
                    format = .json
                }
                
                let exportService = ExportImportService.shared
                let importResult = exportService.importBookmarks(from: data, format: format)
                
                switch importResult {
                case .success(let summary):
                    print("Import successful: \(summary.imported) imported, \(summary.skipped) skipped")
                case .failure(let error):
                    print("Import failed: \(error)")
                }
                
            } catch {
                print("Import error: \(error)")
            }
            
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
}

struct SyncStatusView: View {
    @EnvironmentObject private var persistenceController: PersistenceController
    
    var body: some View {
        HStack(spacing: 6) {
            syncIcon
            
            Text(syncStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var syncIcon: some View {
        switch persistenceController.syncStatus {
        case .idle:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .syncing:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.blue)
                .symbolEffect(.rotate)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .error(_):
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
        }
    }
    
    private var syncStatusText: String {
        switch persistenceController.syncStatus {
        case .idle:
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Sync Complete"
        case .error(let message):
            return "Error"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PersistenceController.shared)
}
