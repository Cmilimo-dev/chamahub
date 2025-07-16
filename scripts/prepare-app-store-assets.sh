#!/bin/bash

echo "🎨 Preparing ChamaHub App Store Assets..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create assets directory
mkdir -p assets/app-store
mkdir -p assets/app-store/android
mkdir -p assets/app-store/ios
mkdir -p assets/app-store/screenshots

echo -e "${YELLOW}📱 Creating app icons for different sizes...${NC}"

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo -e "${RED}❌ ImageMagick not found. Installing...${NC}"
    if command -v brew &> /dev/null; then
        brew install imagemagick
    else
        echo -e "${RED}❌ Please install ImageMagick or Homebrew first${NC}"
        exit 1
    fi
fi

# Source logo
SOURCE_LOGO="logo.svg"
if [ ! -f "$SOURCE_LOGO" ]; then
    echo -e "${RED}❌ Source logo not found at $SOURCE_LOGO${NC}"
    exit 1
fi

# Android Play Store Assets
echo -e "${YELLOW}🤖 Creating Android Play Store assets...${NC}"

# Play Store icon (512x512)
magick "$SOURCE_LOGO" -resize 512x512 assets/app-store/android/play-store-icon.png

# Feature graphic (1024x500)
magick "$SOURCE_LOGO" -resize 300x300 -background "#16a34a" -gravity center -extent 1024x500 assets/app-store/android/feature-graphic.png

# High-res icon (512x512)
magick "$SOURCE_LOGO" -resize 512x512 assets/app-store/android/high-res-icon.png

# iOS App Store Assets
echo -e "${YELLOW}🍎 Creating iOS App Store assets...${NC}"

# App Store icon (1024x1024)
magick "$SOURCE_LOGO" -resize 1024x1024 assets/app-store/ios/app-store-icon.png

# iPhone screenshots placeholders (create template)
magick -size 1290x2796 xc:"#16a34a" -fill white -gravity center -pointsize 72 -annotate +0+0 "ChamaHub\nFinancial Management" assets/app-store/screenshots/iphone-6.5-1.png
magick -size 1290x2796 xc:"#10b981" -fill white -gravity center -pointsize 72 -annotate +0+0 "Group\nContributions" assets/app-store/screenshots/iphone-6.5-2.png
magick -size 1290x2796 xc:"#059669" -fill white -gravity center -pointsize 72 -annotate +0+0 "Loan\nManagement" assets/app-store/screenshots/iphone-6.5-3.png

# Android screenshots placeholders
magick -size 1080x1920 xc:"#16a34a" -fill white -gravity center -pointsize 64 -annotate +0+0 "ChamaHub\nFinancial Management" assets/app-store/screenshots/android-phone-1.png
magick -size 1080x1920 xc:"#10b981" -fill white -gravity center -pointsize 64 -annotate +0+0 "Group\nContributions" assets/app-store/screenshots/android-phone-2.png
magick -size 1080x1920 xc:"#059669" -fill white -gravity center -pointsize 64 -annotate +0+0 "Loan\nManagement" assets/app-store/screenshots/android-phone-3.png

echo -e "${GREEN}✅ App Store assets created successfully!${NC}"
echo -e "${BLUE}📂 Assets location: ./assets/app-store/${NC}"
echo -e "${BLUE}📱 Android assets: ./assets/app-store/android/${NC}"
echo -e "${BLUE}🍎 iOS assets: ./assets/app-store/ios/${NC}"
echo -e "${BLUE}📸 Screenshots: ./assets/app-store/screenshots/${NC}"

# Create app store descriptions
echo -e "${YELLOW}📝 Creating app store descriptions...${NC}"

cat > assets/app-store/app-description.md << 'EOF'
# ChamaHub - Financial Management App

## Short Description
Streamline your group financial management with ChamaHub - the ultimate app for chama groups, savings circles, and investment clubs.

## Full Description
ChamaHub is a comprehensive financial management platform designed specifically for chama groups, savings circles, and investment clubs. Our app simplifies group financial operations with powerful features:

### Key Features:
- **Group Management**: Create and manage multiple chama groups
- **Contribution Tracking**: Record and track member contributions
- **Loan Management**: Apply for loans, track repayments, and manage approvals
- **Real-time Analytics**: View group financial performance and insights
- **Secure Payments**: Integrated M-Pesa and other payment methods
- **Member Invitations**: Invite members via email or SMS
- **Meeting Scheduling**: Plan and track group meetings
- **Financial Reports**: Generate detailed financial reports
- **Push Notifications**: Stay updated on group activities
- **Multi-language Support**: Available in multiple languages

### Perfect for:
- Chama groups
- Savings circles
- Investment clubs
- Cooperative societies
- Financial groups
- Community organizations

### Security & Privacy:
- Bank-level security
- Encrypted data transmission
- Regular security audits
- Privacy-focused design

Transform your group's financial management today with ChamaHub!

## Keywords
chama, savings, investment, group finance, financial management, mobile banking, Kenya, cooperative, savings circle, investment club

## Category
Finance

## Age Rating
4+ (suitable for all ages)
EOF

echo -e "${GREEN}✅ App store description created!${NC}"
echo -e "${BLUE}📄 Description file: ./assets/app-store/app-description.md${NC}"

# Create privacy policy template
cat > assets/app-store/privacy-policy.md << 'EOF'
# ChamaHub Privacy Policy

## Information We Collect
- Account information (name, email, phone number)
- Financial transaction data
- Group membership information
- Device information for security purposes

## How We Use Your Information
- To provide financial management services
- To facilitate group transactions
- To send important notifications
- To improve our services

## Data Security
- All data is encrypted in transit and at rest
- We use industry-standard security measures
- Regular security audits and updates
- No data sharing with third parties without consent

## Your Rights
- Access your personal data
- Request data deletion
- Update your information
- Opt-out of communications

## Contact Us
Email: privacy@chamahub.com
Phone: +254 XXX XXX XXX
Address: [Your Address]

Last updated: [Current Date]
EOF

echo -e "${GREEN}✅ Privacy policy template created!${NC}"
echo -e "${BLUE}📄 Privacy policy: ./assets/app-store/privacy-policy.md${NC}"

echo -e "${GREEN}🎉 All app store assets and metadata prepared successfully!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "${BLUE}1. Review and customize the app description${NC}"
echo -e "${BLUE}2. Take actual screenshots of your app${NC}"
echo -e "${BLUE}3. Set up Google Play Console and App Store Connect accounts${NC}"
echo -e "${BLUE}4. Upload assets and submit for review${NC}"
