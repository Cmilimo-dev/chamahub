#!/bin/bash

echo "🚀 Building ChamaHub Android App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Android SDK is available
if [ -z "$ANDROID_HOME" ]; then
    echo -e "${RED}❌ ANDROID_HOME not set. Please install Android SDK.${NC}"
    exit 1
fi

# Build web app first
echo -e "${YELLOW}📦 Building web application...${NC}"
npm run build

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

# Build debug APK
echo -e "${YELLOW}🔨 Building debug APK...${NC}"
cd android && ./gradlew assembleDebug

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Android build failed${NC}"
    exit 1
fi

# Success message
echo -e "${GREEN}✅ Android build completed successfully!${NC}"
echo -e "${GREEN}📱 APK location: android/app/build/outputs/apk/debug/app-debug.apk${NC}"
echo -e "${GREEN}🎉 You can now install this APK on Android devices!${NC}"

# Optional: Show APK info
if command -v aapt &> /dev/null; then
    echo -e "${YELLOW}📋 APK Information:${NC}"
    aapt dump badging android/app/build/outputs/apk/debug/app-debug.apk | grep -E "(package|label|icon|application-label)"
fi
