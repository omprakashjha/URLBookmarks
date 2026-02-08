# Web App Setup Guide

## Prerequisites

1. **Node.js 18+** - Download from [nodejs.org](https://nodejs.org/)
2. **Apple Developer Account** - Required for CloudKit Web Services
3. **Same CloudKit Container** - Must use the same container as macOS/iOS apps

## Project Setup

### 1. Install Dependencies
```bash
cd /Users/opjha/Stash/Web
npm install
```

### 2. CloudKit Web Services Configuration

#### Step 1: Enable CloudKit Web Services
1. Go to [CloudKit Console](https://icloud.developer.apple.com/dashboard/)
2. Select your container: `iCloud.com.yourteam.stash`
3. Go to "Settings" → "CloudKit Web Services"
4. Click "Enable CloudKit Web Services"

#### Step 2: Configure Web Authentication
1. In CloudKit Console, go to "Settings" → "CloudKit Web Services"
2. Add your domain(s):
   - Development: `http://localhost:3000`
   - Production: `https://yourdomain.com`
3. Generate API Token:
   - Click "Create API Token"
   - Copy the generated token

#### Step 3: Set Environment Variables
Create `.env` file in the Web directory:
```bash
REACT_APP_CLOUDKIT_API_TOKEN=your_api_token_here
```

### 3. Update Configuration
Edit `src/services/CloudKitService.js`:
```javascript
const CLOUDKIT_CONFIG = {
  containerIdentifier: 'iCloud.com.yourteam.stash', // Match your container
  apiTokenAuth: {
    apiToken: process.env.REACT_APP_CLOUDKIT_API_TOKEN,
    persist: true
  },
  environment: 'development' // or 'production'
};
```

### 4. Run the Development Server
```bash
npm start
```

The app will open at `http://localhost:3000`

## Features Implemented

✅ **CloudKit JS Integration**
- Direct connection to same CloudKit container as native apps
- Real-time sync with macOS and iOS apps
- Apple ID authentication

✅ **Web-Optimized Interface**
- Responsive design for desktop and mobile browsers
- Grid layout for bookmark cards
- Search functionality with real-time filtering

✅ **URL Management**
- Add URLs with clipboard detection
- Click to open URLs in new tabs
- Delete bookmarks with confirmation
- Export/import JSON functionality

✅ **Progressive Web App (PWA)**
- Installable on desktop and mobile
- Offline-capable with service worker
- Native app-like experience

✅ **Cross-Platform Sync**
- Shares data with macOS and iOS apps
- Real-time synchronization via CloudKit
- Conflict resolution with timestamp comparison

## Web-Specific Features

### Browser Integration
- **Clipboard Detection** - Auto-populate URL field from clipboard
- **New Tab Opening** - URLs open in new tabs with security attributes
- **Responsive Design** - Works on desktop, tablet, and mobile browsers

### PWA Capabilities
- **Installable** - Can be installed as desktop/mobile app
- **Offline Support** - Basic functionality works without internet
- **App-like Experience** - Full-screen mode, app icons

### Import/Export
- **JSON Export** - Download bookmarks as JSON file
- **JSON Import** - Upload and import bookmark files
- **Cross-Platform Compatible** - Same format as native apps

## Data Synchronization

The web app syncs in real-time with:
- **macOS app** - Same CloudKit container
- **iOS app** - Same CloudKit container
- **Other browsers** - When signed in to same Apple ID

### Sync Behavior
- **Automatic** - Changes sync immediately when online
- **Real-time** - See changes from other devices instantly
- **Offline Queue** - Changes saved locally and synced when online
- **Conflict Resolution** - Last-write-wins with timestamp comparison

## Testing Cross-Platform Sync

1. **Add bookmark on web** - Should appear on macOS/iOS within seconds
2. **Add bookmark on macOS** - Should appear on web instantly
3. **Delete on iOS** - Should disappear from web immediately
4. **Sign out/in** - Data persists and syncs correctly

## Browser Extension (Future)

The web app is designed to support a browser extension that can:
- Save current page URL with one click
- Sync saved URLs via same CloudKit container
- Access bookmarks from extension popup

## Deployment

### Development
```bash
npm start
```

### Production Build
```bash
npm run build
```

### Deploy to Static Hosting
The built files in `build/` can be deployed to:
- **Netlify** - Drag and drop deployment
- **Vercel** - Git-based deployment
- **GitHub Pages** - Static site hosting
- **AWS S3** - Static website hosting

### Environment Configuration
For production, update:
1. **CloudKit Environment** - Change to 'production' in config
2. **Domain Whitelist** - Add production domain to CloudKit Console
3. **API Token** - Use production environment variables

## Troubleshooting

### CloudKit Issues
- Verify API token is correct and not expired
- Check domain is whitelisted in CloudKit Console
- Ensure container identifier matches native apps

### Authentication Issues
- Clear browser cache and cookies
- Check Apple ID is signed in to iCloud
- Verify CloudKit Web Services is enabled

### Sync Issues
- Check network connection
- Verify same Apple ID across all devices
- Check CloudKit Console for error logs

### Build Issues
- Clear node_modules and reinstall: `rm -rf node_modules && npm install`
- Check Node.js version: `node --version`
- Verify environment variables are set correctly

## Next Steps

After the web app is working:
1. **Task 4**: Add platform-specific integrations
2. **Task 5**: Create browser extension
3. **Task 6**: Add PWA features and offline support
4. **Task 7**: Polish UI/UX and optimize performance
