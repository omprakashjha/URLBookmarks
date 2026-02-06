# iOS App Setup Guide

## Prerequisites

1. **Xcode 15.0+** - Download from Mac App Store or Apple Developer
2. **iOS 16.0+** - Required for deployment target
3. **Apple Developer Account** - Required for CloudKit container setup
4. **Same CloudKit Container** - Must use the same container as macOS app

## Project Setup

### 1. Open the Project
```bash
cd /Users/opjha/Stash/iOS
open Stash.xcodeproj
```

### 2. Configure Development Team
1. Select the project in Xcode navigator
2. Go to "Signing & Capabilities" tab
3. Select your development team (same as macOS app)
4. Use the same bundle identifier: `com.yourteam.stash`

### 3. CloudKit Container Setup
1. In Xcode, go to "Signing & Capabilities"
2. Verify CloudKit capability is enabled
3. **Important**: Use the same CloudKit container as macOS app:
   - Container: `iCloud.com.yourteam.stash`
   - Update container identifier in:
     - `Stash.entitlements`
     - `PersistenceController.swift` (shared file)

### 4. Shared Files
The iOS app shares Core Data files with macOS via symbolic links:
- `PersistenceController.swift` → `../../Shared/PersistenceController.swift`
- `URLBookmark+CoreDataClass.swift` → `../../Shared/URLBookmark+CoreDataClass.swift`
- `Stash.xcdatamodeld` → `../../Shared/Stash.xcdatamodeld`

### 5. Build and Run
1. Select "Stash" scheme
2. Choose iOS Simulator or connected device
3. Press ⌘+R to build and run

## Features Implemented

✅ **SwiftUI Interface**
- Navigation stack with list and detail views
- Search functionality with real-time filtering
- Native iOS design patterns and interactions

✅ **Core Data + CloudKit Integration**
- Shares the same CloudKit container as macOS app
- Automatic sync between iOS and macOS devices
- User-controlled sync enable/disable

✅ **URL Management**
- Add URLs with clipboard detection
- Edit bookmark details with native forms
- Delete bookmarks with swipe gestures
- Safari integration for opening URLs

✅ **Import/Export**
- Export bookmarks as JSON with share sheet
- Import bookmarks from JSON files
- Native file picker integration

✅ **Settings & Preferences**
- iCloud sync toggle with status indicators
- Manual sync trigger
- About information

## iOS-Specific Features

### Native Integrations
- **Safari Integration** - Open URLs in SFSafariViewController
- **Share Sheet** - Native sharing for URLs and export files
- **File Picker** - Native document picker for imports
- **Clipboard Detection** - Auto-populate URL field from clipboard

### Mobile Optimizations
- **Touch-First Interface** - Optimized for finger navigation
- **Swipe Gestures** - Swipe to delete bookmarks
- **Form Sheets** - Native modal presentations
- **Keyboard Handling** - Proper focus management and keyboard types

### Responsive Design
- **iPhone & iPad Support** - Adaptive layouts for all screen sizes
- **Portrait & Landscape** - Supports all orientations
- **Dynamic Type** - Respects user's text size preferences
- **Dark Mode** - Automatic dark/light mode support

## Data Synchronization

The iOS app automatically syncs with:
- **macOS app** - Same CloudKit container
- **Other iOS devices** - Signed in to same iCloud account
- **Future web app** - Will use same CloudKit data

### Sync Behavior
- **Automatic** - Changes sync in background when iCloud is enabled
- **Manual** - Tap "Sync Now" in settings for immediate sync
- **Offline** - Works offline, syncs when connection restored
- **Conflict Resolution** - Last-write-wins with timestamp comparison

## Testing Sync

1. **Setup both apps** with same CloudKit container
2. **Add bookmark on macOS** - Should appear on iOS within seconds
3. **Add bookmark on iOS** - Should appear on macOS within seconds
4. **Toggle sync off** - Changes stay local only
5. **Toggle sync on** - Local changes merge with cloud data

## Next Steps

After the iOS app is working:
1. **Task 3**: Create React web app with CloudKit JS
2. **Task 4**: Add platform-specific integrations (share extensions, widgets)
3. **Task 5**: Implement cross-platform export/import
4. **Task 6**: Add browser extensions and PWA features

## Troubleshooting

### CloudKit Issues
- Ensure same CloudKit container as macOS app
- Verify you're signed in to iCloud on device
- Check CloudKit console shows both apps using same container

### Sync Issues
- Check iCloud account status in Settings app
- Verify both apps have same bundle identifier prefix
- Enable CloudKit logging for debugging

### Build Issues
- Clean build folder (⌘+⇧+K)
- Verify deployment target matches your iOS version
- Check symbolic links are working correctly
