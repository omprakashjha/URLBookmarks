# Platform Integrations Setup Guide

## Overview

This guide covers setting up platform-specific integrations for the Stash app:

- **iOS**: Share Extension + Home Screen Widget
- **macOS**: Spotlight Integration + System Services
- **Web**: Browser Extension + PWA Features

## iOS Integrations

### Share Extension Setup

1. **Add Share Extension Target**
   ```bash
   # In Xcode, add new target:
   # File → New → Target → iOS → Share Extension
   # Name: "ShareExtension"
   # Bundle ID: com.stash.app.ShareExtension
   ```

2. **Configure Info.plist**
   - Copy `iOS/ShareExtension/Info.plist` to your share extension target
   - Update bundle identifier to match your app

3. **Add Shared Framework**
   - Add Core Data framework to share extension target
   - Link shared `PersistenceController.swift` and data model
   - Enable App Groups capability for data sharing

### Widget Setup

1. **Add Widget Extension Target**
   ```bash
   # In Xcode, add new target:
   # File → New → Target → iOS → Widget Extension
   # Name: "BookmarkWidget"
   # Bundle ID: com.stash.app.BookmarkWidget
   ```

2. **Configure Widget**
   - Copy `iOS/BookmarkWidget/BookmarkWidget.swift` to widget target
   - Link shared Core Data files
   - Enable App Groups capability

3. **Test Widget**
   - Run widget target on device/simulator
   - Add widget to home screen
   - Verify recent bookmarks display correctly

## macOS Integrations

### Spotlight Integration

1. **Add Core Spotlight Framework**
   ```swift
   // In Xcode project settings:
   // Target → Build Phases → Link Binary With Libraries
   // Add: CoreSpotlight.framework
   ```

2. **Configure Spotlight Indexing**
   - Copy `macOS/SpotlightIndexer.swift` to macOS target
   - Update `PersistenceController.swift` with Spotlight integration
   - Update `StashApp.swift` to handle Spotlight selections

3. **Test Spotlight Search**
   - Add bookmarks in the app
   - Search for bookmark titles/URLs in Spotlight
   - Verify clicking results opens URLs

### System Services (Optional)

1. **Add System Service**
   ```xml
   <!-- Add to Info.plist -->
   <key>NSServices</key>
   <array>
     <dict>
       <key>NSMenuItem</key>
       <dict>
         <key>default</key>
         <string>Save URL to Bookmarks</string>
       </dict>
       <key>NSMessage</key>
       <string>saveURLFromService</string>
       <key>NSPortName</key>
       <string>Stash</string>
       <key>NSSendTypes</key>
       <array>
         <string>NSStringPboardType</string>
       </array>
     </dict>
   </array>
   ```

## Browser Extension

### Chrome Extension Setup

1. **Load Extension in Chrome**
   ```bash
   # Open Chrome and go to:
   # chrome://extensions/
   # Enable "Developer mode"
   # Click "Load unpacked"
   # Select: /Users/opjha/Stash/BrowserExtension/
   ```

2. **Configure Web App Integration**
   - Update domain references in extension files:
     - `popup.js` - Update `your-web-app-domain.com`
     - `content.js` - Update domain check
     - `background.js` - Update sync URL

3. **Test Extension**
   - Click extension icon in toolbar
   - Verify current page URL/title populate
   - Save bookmark and check local storage
   - Test right-click context menu

### Firefox Extension (Optional)

1. **Convert Manifest**
   ```json
   // Create manifest-v2.json for Firefox
   {
     "manifest_version": 2,
     "name": "Stash",
     "version": "1.0.0",
     "permissions": ["activeTab", "storage", "contextMenus"],
     "background": {
       "scripts": ["background.js"],
       "persistent": false
     },
     "browser_action": {
       "default_popup": "popup.html"
     }
   }
   ```

2. **Load in Firefox**
   ```bash
   # Go to: about:debugging
   # Click "This Firefox"
   # Click "Load Temporary Add-on"
   # Select manifest-v2.json
   ```

## Web App PWA Features

### Service Worker Setup

1. **Create Service Worker**
   ```javascript
   // Add to Web/public/sw.js
   const CACHE_NAME = 'stash-v1';
   const urlsToCache = [
     '/',
     '/static/js/bundle.js',
     '/static/css/main.css'
   ];

   self.addEventListener('install', (event) => {
     event.waitUntil(
       caches.open(CACHE_NAME)
         .then((cache) => cache.addAll(urlsToCache))
     );
   });

   self.addEventListener('fetch', (event) => {
     event.respondWith(
       caches.match(event.request)
         .then((response) => response || fetch(event.request))
     );
   });
   ```

2. **Register Service Worker**
   ```javascript
   // Add to Web/src/index.js
   if ('serviceWorker' in navigator) {
     window.addEventListener('load', () => {
       navigator.serviceWorker.register('/sw.js')
         .then((registration) => {
           console.log('SW registered: ', registration);
         })
         .catch((registrationError) => {
           console.log('SW registration failed: ', registrationError);
         });
     });
   }
   ```

### Install Prompt

1. **Add Install Button**
   ```javascript
   // Add to Web/src/App.js
   const [deferredPrompt, setDeferredPrompt] = useState(null);
   const [showInstallButton, setShowInstallButton] = useState(false);

   useEffect(() => {
     window.addEventListener('beforeinstallprompt', (e) => {
       e.preventDefault();
       setDeferredPrompt(e);
       setShowInstallButton(true);
     });
   }, []);

   const handleInstall = async () => {
     if (deferredPrompt) {
       deferredPrompt.prompt();
       const { outcome } = await deferredPrompt.userChoice;
       if (outcome === 'accepted') {
         setShowInstallButton(false);
       }
       setDeferredPrompt(null);
     }
   };
   ```

## Cross-Platform Testing

### Sync Testing Checklist

1. **macOS ↔ iOS Sync**
   - [ ] Add bookmark on macOS → appears on iOS
   - [ ] Add bookmark on iOS → appears on macOS
   - [ ] Delete on macOS → removed from iOS
   - [ ] Edit on iOS → updated on macOS
   - [ ] Offline changes sync when online

2. **Native ↔ Web Sync**
   - [ ] Add bookmark on web → appears on native apps
   - [ ] Add bookmark on native → appears on web
   - [ ] Real-time sync (changes appear within seconds)
   - [ ] Conflict resolution works correctly

3. **Extension Integration**
   - [ ] Browser extension saves to local storage
   - [ ] Extension communicates with web app when open
   - [ ] Context menu saves bookmarks
   - [ ] Extension popup shows current page info

### Platform-Specific Features

1. **iOS Features**
   - [ ] Share extension works from Safari
   - [ ] Share extension works from other apps
   - [ ] Widget displays recent bookmarks
   - [ ] Widget opens URLs when tapped
   - [ ] Widget updates automatically

2. **macOS Features**
   - [ ] Spotlight finds bookmarks by title/URL
   - [ ] Spotlight results open URLs
   - [ ] Menu bar shortcuts work
   - [ ] Drag & drop URLs works

3. **Web Features**
   - [ ] PWA installs on desktop/mobile
   - [ ] Offline functionality works
   - [ ] Browser extension integrates
   - [ ] Clipboard detection works

## Troubleshooting

### iOS Issues
- **Share extension not appearing**: Check Info.plist configuration and supported types
- **Widget not updating**: Verify App Groups and Core Data sharing
- **CloudKit sync failing**: Check entitlements and container configuration

### macOS Issues
- **Spotlight not indexing**: Check Core Spotlight framework and permissions
- **Menu shortcuts not working**: Verify command registration in App.swift
- **Drag & drop not working**: Check window delegate and accepted types

### Browser Extension Issues
- **Extension not loading**: Check manifest.json syntax and permissions
- **Web app communication failing**: Verify domain matching and content script injection
- **Context menu not appearing**: Check permissions and menu registration

### Web App Issues
- **PWA not installing**: Check manifest.json and HTTPS requirement
- **Service worker not caching**: Verify SW registration and cache strategy
- **CloudKit authentication failing**: Check API token and domain whitelist

## Performance Optimization

### iOS Optimizations
- Use background app refresh for sync
- Implement efficient Core Data fetching
- Optimize widget timeline updates

### macOS Optimizations
- Batch Spotlight indexing operations
- Use efficient search predicates
- Implement lazy loading for large datasets

### Web Optimizations
- Implement virtual scrolling for large lists
- Use service worker for offline caching
- Optimize CloudKit API calls with batching

## Security Considerations

### Data Protection
- Enable Core Data encryption
- Use App Transport Security (ATS)
- Implement proper CloudKit permissions

### Extension Security
- Validate all user inputs
- Use content security policy
- Limit extension permissions to minimum required

### Web Security
- Implement HTTPS everywhere
- Use secure CloudKit authentication
- Validate all API responses

## Deployment

### iOS App Store
1. Configure app signing and provisioning
2. Add share extension and widget to main app bundle
3. Test on physical devices
4. Submit for App Store review

### Mac App Store
1. Enable sandbox and hardened runtime
2. Configure Spotlight entitlements
3. Test notarization process
4. Submit for Mac App Store review

### Browser Extension Stores
1. Package extension for Chrome Web Store
2. Create Firefox add-on package
3. Prepare store listings and screenshots
4. Submit for review

### Web App Deployment
1. Build production version with optimizations
2. Configure CloudKit for production environment
3. Deploy to CDN or static hosting
4. Set up custom domain and SSL certificate
