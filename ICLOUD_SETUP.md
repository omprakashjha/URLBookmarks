# iCloud Sync Setup Guide

## Prerequisites
- Apple Developer Account (paid membership required)
- Xcode installed
- Signed in to Xcode with your Apple ID

## Step-by-Step Setup

### 1. Configure Xcode Signing (iOS App)

1. Open `iOS/Stash.xcodeproj` in Xcode
2. Select the **Stash** target
3. Go to **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your **Team** from dropdown
6. Xcode will automatically provision the app

### 2. Enable iCloud Capability (iOS)

1. Still in **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add **iCloud**
4. Check **CloudKit**
5. The container `iCloud.com.stash.app` should appear
6. If not, click **+** and add it manually

### 3. Configure Xcode Signing (macOS App)

1. Open `macOS/Stash.xcodeproj` in Xcode
2. Select the **Stash** target
3. Go to **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your **Team** from dropdown

### 4. Enable iCloud Capability (macOS)

1. Still in **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add **iCloud**
4. Check **CloudKit**
5. Ensure `iCloud.com.stash.app` container is selected

### 5. CloudKit Dashboard Setup

1. Go to CloudKit Dashboard: https://icloud.developer.apple.com/dashboard
2. Select your container: `iCloud.com.stash.app`
3. Go to **Schema** → **Record Types**
4. Create the following record type:

**URLBookmark** with fields:
- `url` (String, required)
- `title` (String)
- `notes` (String)
- `createdAt` (Date/Time, required)
- `modifiedAt` (Date/Time, required)
- `isDeleted` (Int64, required)

5. Add indexes:
- Index on `url`
- Index on `createdAt`
- Index on `modifiedAt`

6. Go to **Schema** → **Custom Zones**
7. Create zone: `StashZone`

### 6. Test the Setup

#### iOS:
```bash
cd iOS
xcodebuild -project Stash.xcodeproj -scheme Stash -destination 'platform=iOS Simulator,name=iPhone 15' build
```

#### macOS:
```bash
cd macOS
xcodebuild -project Stash.xcodeproj -scheme Stash build
```

### 7. Verify Sync

1. Run the iOS app on a device (not simulator for full CloudKit testing)
2. Sign in with your Apple ID in Settings → iCloud
3. Add a bookmark in the iOS app
4. Run the macOS app
5. Sign in with the same Apple ID
6. The bookmark should sync automatically

## Current Configuration

Your apps are already configured with:
- ✅ Entitlements files with CloudKit enabled
- ✅ Container ID: `iCloud.com.stash.app`
- ✅ Bundle ID: `com.stash.app`
- ✅ NSPersistentCloudKitContainer setup
- ✅ Automatic sync with Core Data
- ✅ Remote change notifications

## Troubleshooting

### "No iCloud account" error
- Ensure you're signed in to iCloud on the device
- Go to Settings → [Your Name] → iCloud

### Sync not working
- Check CloudKit Dashboard for errors
- Verify container ID matches in all places
- Ensure both apps use the same Apple ID for testing

### Development vs Production
- Development: Use Xcode's automatic provisioning
- Production: Create explicit App Store provisioning profiles

## Quick Commands

Check if CloudKit is accessible:
```bash
# iOS
xcrun simctl icloud_sync <device-id>

# Check container status in code
# The PersistenceController will log errors if CloudKit fails
```

## Notes

- CloudKit sync works automatically via NSPersistentCloudKitContainer
- No manual sync code needed - Core Data handles it
- Sync happens in background when network is available
- Conflicts are resolved automatically (last-write-wins)
- The `CrossPlatformSyncManager` provides additional sync status UI
