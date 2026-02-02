import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var persistenceController: PersistenceController
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(persistenceController)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            SyncSettingsView()
                .environmentObject(persistenceController)
                .tabItem {
                    Label("Sync", systemImage: "icloud")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("About URL Bookmarks")
                    .font(.headline)
                
                Text("A simple and intuitive URL bookmarking app with iCloud sync.")
                    .foregroundColor(.secondary)
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SyncSettingsView: View {
    @EnvironmentObject private var persistenceController: PersistenceController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("iCloud Sync Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Enable iCloud Sync", isOn: $persistenceController.isSyncEnabled)
                    .toggleStyle(.switch)
                
                if persistenceController.isSyncEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iCloud sync is enabled. Your bookmarks will be synchronized across all your devices signed in to the same iCloud account.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            SyncStatusView()
                            
                            Spacer()
                            
                            Button("Sync Now") {
                                persistenceController.manualSync()
                            }
                            .disabled(persistenceController.syncStatus == .syncing)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iCloud sync is disabled. Your bookmarks will only be stored locally on this device.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("To sync bookmarks across devices, enable iCloud sync and ensure you're signed in to iCloud on all devices.")
                            .font(.caption)
                            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Data Management")
                    .font(.headline)
                
                HStack {
                    Button("Export All Bookmarks...") {
                        NotificationCenter.default.post(name: .exportURLs, object: nil)
                    }
                    
                    Button("Import Bookmarks...") {
                        NotificationCenter.default.post(name: .importURLs, object: nil)
                    }
                }
                
                Text("Export your bookmarks as a JSON file for backup or transfer to another device.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PersistenceController.shared)
}
