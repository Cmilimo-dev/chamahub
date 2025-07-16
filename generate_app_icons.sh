#!/bin/bash

# ChamaHub App Icon Generator
# This script generates all required Android app icon sizes from the SVG logo

LOGO_FILE="logo.svg"
ANDROID_RES_DIR="android/app/src/main/res"

# Check if logo file exists
if [ ! -f "$LOGO_FILE" ]; then
    echo "Error: $LOGO_FILE not found!"
    exit 1
fi

echo "🎨 Generating ChamaHub app icons..."

# Function to generate icon
generate_icon() {
    local size=$1
    local density=$2
    local output_dir="$ANDROID_RES_DIR/mipmap-$density"
    
    echo "📱 Generating ${density} icons (${size}x${size})"
    
    # Create directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Generate main launcher icon
    convert "$LOGO_FILE" -resize "${size}x${size}" -background transparent "$output_dir/ic_launcher.png"
    
    # Generate round launcher icon
    convert "$LOGO_FILE" -resize "${size}x${size}" -background transparent "$output_dir/ic_launcher_round.png"
    
    # Generate foreground icon (for adaptive icons)
    convert "$LOGO_FILE" -resize "${size}x${size}" -background transparent "$output_dir/ic_launcher_foreground.png"
}

# Generate icons for all Android densities
generate_icon 48 mdpi
generate_icon 72 hdpi
generate_icon 96 xhdpi
generate_icon 144 xxhdpi
generate_icon 192 xxxhdpi

echo "✅ App icons generated successfully!"

# Also update the web favicon
echo "🌐 Updating web favicon..."
convert "$LOGO_FILE" -resize "32x32" -background transparent "public/favicon.ico"

echo "🎉 All icons generated and updated!"
echo ""
echo "Next steps:"
echo "1. Build the app: npm run build"
echo "2. Sync with Capacitor: npx cap sync android"
echo "3. Run the app: npx cap run android"
