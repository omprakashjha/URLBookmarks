#!/bin/bash

# iCloud Sync Configuration Checker
# Run this to verify your CloudKit setup

echo "🔍 Checking iCloud Sync Configuration..."
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed"
    exit 1
fi
echo "✅ Xcode installed"

# Check iOS project
echo ""
echo "📱 iOS App Configuration:"
cd iOS 2>/dev/null || { echo "❌ iOS directory not found"; exit 1; }

BUNDLE_ID=$(xcodebuild -showBuildSettings -project Stash.xcodeproj -target Stash 2>/dev/null | grep PRODUCT_BUNDLE_IDENTIFIER | awk '{print $3}' | head -1)
echo "   Bundle ID: $BUNDLE_ID"

TEAM_ID=$(xcodebuild -showBuildSettings -project Stash.xcodeproj -target Stash 2>/dev/null | grep DEVELOPMENT_TEAM | awk '{print $3}' | head -1)
if [ -z "$TEAM_ID" ]; then
    echo "   ⚠️  Team ID: Not configured - You need to set this in Xcode"
else
    echo "   ✅ Team ID: $TEAM_ID"
fi

if [ -f "Stash/Stash.entitlements" ]; then
    echo "   ✅ Entitlements file exists"
    if grep -q "CloudKit" "Stash/Stash.entitlements"; then
        echo "   ✅ CloudKit enabled in entitlements"
    else
        echo "   ❌ CloudKit not found in entitlements"
    fi
    
    CONTAINER=$(grep -A1 "icloud-container-identifiers" "Stash/Stash.entitlements" | grep "string" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "   Container: $CONTAINER"
else
    echo "   ❌ Entitlements file not found"
fi

# Check macOS project
echo ""
echo "💻 macOS App Configuration:"
cd ../macOS 2>/dev/null || { echo "❌ macOS directory not found"; exit 1; }

BUNDLE_ID=$(xcodebuild -showBuildSettings -project Stash.xcodeproj -target Stash 2>/dev/null | grep PRODUCT_BUNDLE_IDENTIFIER | awk '{print $3}' | head -1)
echo "   Bundle ID: $BUNDLE_ID"

TEAM_ID=$(xcodebuild -showBuildSettings -project Stash.xcodeproj -target Stash 2>/dev/null | grep DEVELOPMENT_TEAM | awk '{print $3}' | head -1)
if [ -z "$TEAM_ID" ]; then
    echo "   ⚠️  Team ID: Not configured - You need to set this in Xcode"
else
    echo "   ✅ Team ID: $TEAM_ID"
fi

if [ -f "Stash/Stash.entitlements" ]; then
    echo "   ✅ Entitlements file exists"
    if grep -q "CloudKit" "Stash/Stash.entitlements"; then
        echo "   ✅ CloudKit enabled in entitlements"
    else
        echo "   ❌ CloudKit not found in entitlements"
    fi
    
    CONTAINER=$(grep -A1 "icloud-container-identifiers" "Stash/Stash.entitlements" | grep "string" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "   Container: $CONTAINER"
else
    echo "   ❌ Entitlements file not found"
fi

# Check Shared code
echo ""
echo "🔄 Shared Sync Code:"
cd ../Shared 2>/dev/null || { echo "❌ Shared directory not found"; exit 1; }

if [ -f "PersistenceController.swift" ]; then
    echo "   ✅ PersistenceController.swift exists"
    if grep -q "NSPersistentCloudKitContainer" "PersistenceController.swift"; then
        echo "   ✅ CloudKit container configured"
    fi
fi

if [ -f "CrossPlatformSyncManager.swift" ]; then
    echo "   ✅ CrossPlatformSyncManager.swift exists"
fi

if [ -f "CloudKitSchema.json" ]; then
    echo "   ✅ CloudKitSchema.json exists"
fi

echo ""
echo "📋 Next Steps:"
echo ""
if [ -z "$TEAM_ID" ]; then
    echo "1. Open iOS/Stash.xcodeproj in Xcode"
    echo "2. Select Stash target → Signing & Capabilities"
    echo "3. Check 'Automatically manage signing'"
    echo "4. Select your Team"
    echo "5. Repeat for macOS/Stash.xcodeproj"
    echo ""
fi
echo "6. Open CloudKit Dashboard: https://icloud.developer.apple.com/dashboard"
echo "7. Select container: iCloud.com.stash.app"
echo "8. Import schema from Shared/CloudKitSchema.json"
echo "9. Deploy schema to Production"
echo ""
echo "📖 See ICLOUD_SETUP.md for detailed instructions"
