import SwiftUI

struct SyncStatusView: View {
    @EnvironmentObject private var persistenceController: PersistenceController
    
    var body: some View {
        HStack(spacing: 4) {
            syncIcon
            
            if persistenceController.isSyncEnabled {
                Text(syncStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            if persistenceController.isSyncEnabled {
                persistenceController.manualSync()
            }
        }
        .help(syncHelpText)
    }
    
    @ViewBuilder
    private var syncIcon: some View {
        switch persistenceController.syncStatus {
        case .idle:
            if persistenceController.isSyncEnabled {
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "icloud.slash")
                    .foregroundColor(.secondary)
            }
            
        case .syncing:
            Image(systemName: "icloud")
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
        case .success:
            Image(systemName: "icloud.and.arrow.up")
                .foregroundColor(.green)
            
        case .error(_):
            Image(systemName: "icloud.slash")
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
            return "Error: \(message)"
        }
    }
    
    private var syncHelpText: String {
        if persistenceController.isSyncEnabled {
            switch persistenceController.syncStatus {
            case .idle, .success:
                return "Click to sync now"
            case .syncing:
                return "Syncing with iCloud..."
            case .error(let message):
                return "Sync error: \(message)"
            }
        } else {
            return "iCloud sync is disabled. Enable in Settings."
        }
    }
}

#Preview {
    HStack {
        SyncStatusView()
            .environmentObject(PersistenceController.shared)
    }
    .padding()
}
