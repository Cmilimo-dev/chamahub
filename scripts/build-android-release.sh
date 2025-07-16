#!/bin/bash

echo "🚀 Building ChamaHub Android App for Production..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Android SDK is available
if [ -z "$ANDROID_HOME" ]; then
    echo -e "${RED}❌ ANDROID_HOME not set. Please install Android SDK.${NC}"
    exit 1
fi

# Build web app for production
echo -e "${YELLOW}📦 Building web application for production...${NC}"
npm run build:prod

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Web build failed${NC}"
    exit 1
fi

# Sync with Capacitor
echo -e "${YELLOW}🔄 Syncing with Capacitor...${NC}"
npx cap sync android

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Capacitor sync failed${NC}"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
cd android && ./gradlew clean

# Build release APK
echo -e "${YELLOW}🔨 Building release APK...${NC}"
./gradlew assembleRelease

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Android release build failed${NC}"
    echo -e "${BLUE}💡 Note: You may need to create a signing key for release builds${NC}"
    echo -e "${BLUE}   Run: keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000${NC}"
    exit 1
fi

# Success message
echo -e "${GREEN}✅ Android release build completed successfully!${NC}"
echo -e "${GREEN}📱 APK location: android/app/build/outputs/apk/release/app-release.apk${NC}"
echo -e "${GREEN}🎉 You can now distribute this APK or upload to Google Play Store!${NC}"

# Show APK info
if command -v aapt &> /dev/null; then
    echo -e "${YELLOW}📋 APK Information:${NC}"
    aapt dump badging android/app/build/outputs/apk/release/app-release.apk | grep -E "(package|label|icon|application-label)"
fi

# Show file size
echo -e "${BLUE}📊 APK Size: $(du -h android/app/build/outputs/apk/release/app-release.apk | cut -f1)${NC}"
