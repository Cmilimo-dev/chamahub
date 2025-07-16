# ChamaHub Mobile App Testing Guide

## App Status
✅ **Successfully built and deployed to Android emulator**

## Current Setup
- **App ID**: com.jcnetglobal.chamahub
- **App Name**: ChamaHub
- **Platform**: Android (iOS can be added later)
- **Server**: Running on http://192.168.100.43:4000 (accessible from mobile)

## Testing the Mobile App

### 1. **Check App Launch**
- The app should launch with the ChamaHub splash screen
- After 3 seconds, it should show the main app

### 2. **Debug Information**
Open the Android emulator's Chrome DevTools to see console logs:
- API_BASE_URL will be logged (should be http://10.0.2.2:4000/api for emulator)
- Window location and user agent info
- Network requests and responses

### 3. **Features to Test**

#### Authentication
- Login with existing credentials (admin@chamahub.com)
- Sign up for new accounts
- Password reset functionality

#### Dashboard
- View groups and member information
- Check contributions and financial data
- Navigate between different sections

#### Loans
- Apply for loans
- View loan status
- Approve/reject loans (for admins)

#### Settings
- Update user profile
- Change password
- View app settings

#### Mobile-Specific Features
- Push notifications (configured)
- Offline handling
- Touch/swipe gestures
- Status bar integration

### 4. **Network Testing**
The app will automatically use:
- `http://10.0.2.2:4000/api` for Android emulator
- `http://192.168.100.43:4000/api` for real devices

### 5. **Debugging Issues**
If you encounter problems:
1. Check Chrome DevTools console for errors
2. Verify server is running on localhost:4000
3. Check network connectivity
4. Look for API request failures

## Running on Real Device

### Prerequisites
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect device via USB
4. Ensure device is on the same Wi-Fi network as your computer

### Steps
1. Build and sync: `npm run build && npx cap sync android`
2. List devices: `npx cap run android --list`
3. Run on device: `npx cap run android --target="YOUR_DEVICE_NAME"`

## Building for Production

### Debug Build
```bash
npm run build
npx cap sync android
cd android
./gradlew assembleDebug
```

### Release Build
```bash
npm run build:prod
npx cap sync android
cd android
./gradlew assembleRelease
```

## Troubleshooting

### Common Issues
1. **Java version errors**: Ensure Java 17 is being used
2. **Network connectivity**: Check if server is accessible from mobile
3. **API errors**: Verify API endpoints are working
4. **Build failures**: Run `./gradlew clean` in android folder

### Logs
- Android logs: `adb logcat`
- App logs: Chrome DevTools when connected to emulator
- Server logs: Check server.js console output

## Next Steps
1. Test all features in the mobile app
2. Fix any mobile-specific UI issues
3. Add iOS support if needed
4. Configure push notifications with Firebase
5. Test on real devices
6. Prepare for app store deployment

## Support
- The app is fully functional with all backend features
- Mobile-optimized UI components
- Proper error handling and loading states
- Network status monitoring
- Device-specific optimizations
