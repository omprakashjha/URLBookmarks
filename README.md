# Stash

A cross-platform URL bookmarking application with iOS, macOS, and web versions featuring CloudKit sync.

## Features

- 📱 **iOS App** - Native SwiftUI with share extension and widgets
- 💻 **macOS App** - Native AppKit with Spotlight integration  
- 🌐 **Web App** - React PWA with offline support
- ☁️ **CloudKit Sync** - Seamless sync across all Apple devices
- 🔍 **Search & Filter** - Fast bookmark search and organization
- 📤 **Export/Import** - JSON, CSV, and HTML export formats
- 🌙 **Dark Mode** - System-aware dark/light theme
- 📱 **Browser Extensions** - Chrome and Firefox support

## Quick Start

### Web App (Demo Mode)
```bash
cd Web
npm install
npm start
```
The web app automatically falls back to demo mode if CloudKit isn't configured.

### iOS/macOS Apps
1. Open `Stash.xcodeproj` in Xcode
2. Configure CloudKit container in project settings
3. Build and run

## Project Structure

```
Stash/
├── iOS/              # SwiftUI iOS app
├── macOS/            # AppKit macOS app  
├── Web/              # React web app
├── Shared/           # Shared Swift code
├── Extensions/       # Browser extensions
└── Documentation/    # Implementation guides
```

## CloudKit Setup

1. Create Apple Developer account
2. Configure CloudKit container
3. Update container ID in project settings

For local testing, the web app includes demo mode with sample data.

## License

MIT License - feel free to use and modify as needed.
