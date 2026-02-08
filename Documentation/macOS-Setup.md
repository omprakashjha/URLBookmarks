# macOS App Setup Guide

## Prerequisites

1. **Xcode 15.0+** - Download from Mac App Store or Apple Developer
2. **macOS 13.0+** - Required for deployment target
3. **Apple Developer Account** - Required for CloudKit container setup

## Project Setup

### 1. Open the Project
```bash
cd /Users/opjha/Stash/macOS
open Stash.xcodeproj
```

### 2. Configure Development Team
1. Select the project in Xcode navigator
2. Go to "Signing & Capabilities" tab
3. Select your development team
4. Ensure bundle identifier is unique: `com.yourteam.stash`

### 3. CloudKit Container Setup
1. In Xcode, go to "Signing & Capabilities"
2. Verify CloudKit capability is enabled
3. Create CloudKit container:
   - Go to [CloudKit Console](https://icloud.developer.apple.com/dashboard/)
   - Create new container: `iCloud.com.yourteam.stash`
   - Update container identifier in:
     - `Stash.entitlements`
     - `PersistenceController.swift`

### 4. CloudKit Schema Setup
1. In CloudKit Console, select your container
2. Go to "Schema" section
3. Create record types based on `Shared/CloudKitSchema.json`:
   - **URLBookmark** record type with fields:
     - `url` (String, required)
     - `title` (String, optional)
     - `notes` (String, optional)
     - `createdAt` (Date/Time, required)
     - `modifiedAt` (Date/Time, required)
     - `isDeleted` (Int64, required)
   - **UserSettings** record type with fields:
     - `syncEnabled` (Int64, required)
     - `lastSyncDate` (Date/Time, optional)

### 5. Build and Run
1. Select "Stash" scheme
2. Choose "My Mac" as destination
3. Press ⌘+R to build and run

## Features Implemented

✅ **Core Data + CloudKit Integration**
- Local storage with automatic iCloud sync
- User-controlled sync enable/disable
- Conflict resolution and data merging

✅ **Native macOS Interface**
- Split view with URL list and detail view
- Search functionality with real-time filtering
- Menu bar integration with keyboard shortcuts

✅ **URL Management**
- Add URLs with optional title and notes
- Edit bookmark details in-place
- Delete bookmarks with soft delete (for sync)
- Duplicate detection

✅ **Import/Export**
- Export bookmarks as JSON
- Import bookmarks from JSON files
- Native file picker integration

✅ **Settings & Preferences**
- iCloud sync toggle with status indicators
- Manual sync trigger
- About information

## Keyboard Shortcuts

- **⌘+N** - Add new URL bookmark
- **⌘+F** - Focus search field
- **⌘+⇧+E** - Export bookmarks
- **⌘+⇧+I** - Import bookmarks
- **⌘+,** - Open preferences
- **⌘+Delete** - Delete selected bookmark

## Next Steps

After the macOS app is working:
1. **Task 2**: Build iOS app with SwiftUI
2. **Task 3**: Create React web app with CloudKit JS
3. **Task 4**: Add platform-specific integrations
4. **Task 5**: Implement export/import across all platforms

## Troubleshooting

### CloudKit Issues
- Ensure you're signed in to iCloud on your Mac
- Verify CloudKit container is properly configured
- Check entitlements file has correct container identifier

### Build Issues
- Clean build folder (⌘+⇧+K)
- Reset package caches if using SPM
- Verify deployment target matches your macOS version

### Sync Issues
- Check iCloud account status in System Preferences
- Verify CloudKit console shows your schema
- Enable CloudKit logging for debugging
