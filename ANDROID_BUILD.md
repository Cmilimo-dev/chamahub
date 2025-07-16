
# Android App Build Instructions

This project has been configured with Capacitor to build as an Android app. Follow these steps to build and run the app on Android devices.

## Prerequisites

1. **Node.js and npm**: Make sure you have Node.js installed
2. **Android Studio**: Download and install Android Studio
3. **Java Development Kit (JDK)**: Install JDK 11 or higher
4. **Git**: For cloning the repository

## Setup Instructions

### 1. Export and Clone Project
1. Use the "Export to Github" button in Lovable to transfer the project to your GitHub repository
2. Clone the project from your GitHub repository:
   ```bash
   git clone <your-github-repo-url>
   cd savings-group-hub
   ```

### 2. Install Dependencies
```bash
npm install
```

### 3. Add Android Platform
```bash
npx cap add android
```

### 4. Update Platform Dependencies
```bash
npx cap update android
```

### 5. Build the Web App
```bash
npm run build
```

### 6. Sync with Native Platform
```bash
npx cap sync android
```

## Running the App

### Option 1: Run on Android Emulator/Device
```bash
npx cap run android
```

This will:
- Open Android Studio
- Build the project
- Run on connected device or emulator

### Option 2: Open in Android Studio
```bash
npx cap open android
```

Then build and run from Android Studio.

## Development Workflow

1. Make changes to your web code
2. Run `npm run build` to build the web assets
3. Run `npx cap sync android` to copy changes to native project
4. Run `npx cap run android` to test on device

## Hot Reload During Development

The app is configured to use hot reload from the Lovable sandbox during development. This means you can see changes in real-time without rebuilding.

## Production Build

For production builds:
1. Update the `server.url` in `capacitor.config.ts` to your production URL
2. Build and sync: `npm run build && npx cap sync android`
3. Open in Android Studio and build release APK

## Troubleshooting

- **Build errors**: Make sure you have the latest Android SDK and build tools
- **Device not detected**: Enable USB debugging on your Android device
- **Gradle issues**: Try cleaning the project in Android Studio
- **Permission issues**: Check that your app has necessary permissions in `android/app/src/main/AndroidManifest.xml`

## App Configuration

The app is configured with:
- **App ID**: `app.lovable.f32c64b7c98144dcb4c7be3d6e3a49e8`
- **App Name**: Savings Group Hub
- **Hot reload URL**: Configured for Lovable sandbox

## Next Steps

After successful Android setup, you can:
1. Add iOS support with `npx cap add ios`
2. Configure app icons and splash screens
3. Add native plugins for enhanced functionality
4. Prepare for Play Store deployment

For more information, visit the [Capacitor documentation](https://capacitorjs.com/docs).
