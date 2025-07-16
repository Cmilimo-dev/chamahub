#!/bin/bash

echo "🔐 Creating Android App Signing Key..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create keystore directory
mkdir -p keystores

# Keystore details
KEYSTORE_NAME="keystores/chamahub-release-key.keystore"
ALIAS_NAME="chamahub-key-alias"
KEY_SIZE=2048
VALIDITY_DAYS=10000

echo -e "${YELLOW}📋 You will be prompted for the following information:${NC}"
echo -e "${BLUE}1. Keystore password (remember this!)${NC}"
echo -e "${BLUE}2. Key password (can be same as keystore password)${NC}"
echo -e "${BLUE}3. Your name and organization details${NC}"
echo -e "${BLUE}4. Country code (e.g., KE for Kenya)${NC}"
echo ""

# Generate keystore
echo -e "${YELLOW}🔑 Generating keystore...${NC}"
keytool -genkey -v -keystore "$KEYSTORE_NAME" -alias "$ALIAS_NAME" -keyalg RSA -keysize $KEY_SIZE -validity $VALIDITY_DAYS

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Keystore created successfully!${NC}"
    echo -e "${BLUE}📂 Keystore location: $KEYSTORE_NAME${NC}"
    echo -e "${BLUE}🔑 Alias: $ALIAS_NAME${NC}"
    
    # Create gradle.properties template
    echo -e "${YELLOW}📝 Creating gradle.properties template...${NC}"
    
    cat > android/gradle.properties.template << EOF
# Signing configuration
# Copy this to gradle.properties and fill in your actual values
MYAPP_UPLOAD_STORE_FILE=../keystores/chamahub-release-key.keystore
MYAPP_UPLOAD_KEY_ALIAS=chamahub-key-alias
MYAPP_UPLOAD_STORE_PASSWORD=your_keystore_password_here
MYAPP_UPLOAD_KEY_PASSWORD=your_key_password_here
EOF

    echo -e "${GREEN}✅ gradle.properties template created!${NC}"
    echo -e "${BLUE}📄 Template location: android/gradle.properties.template${NC}"
    
    # Update build.gradle for signing
    echo -e "${YELLOW}📝 Updating build.gradle for signing...${NC}"
    
    # Backup original build.gradle
    cp android/app/build.gradle android/app/build.gradle.backup
    
    # Add signing configuration
    cat >> android/app/build.gradle << 'EOF'

// Add this signing configuration
android {
    signingConfigs {
        release {
            if (project.hasProperty('MYAPP_UPLOAD_STORE_FILE')) {
                storeFile file(MYAPP_UPLOAD_STORE_FILE)
                storePassword MYAPP_UPLOAD_STORE_PASSWORD
                keyAlias MYAPP_UPLOAD_KEY_ALIAS
                keyPassword MYAPP_UPLOAD_KEY_PASSWORD
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
EOF

    echo -e "${GREEN}✅ build.gradle updated for signing!${NC}"
    
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo -e "${BLUE}1. Copy android/gradle.properties.template to android/gradle.properties${NC}"
    echo -e "${BLUE}2. Edit android/gradle.properties with your actual passwords${NC}"
    echo -e "${BLUE}3. Run: npm run android:build:bundle${NC}"
    echo -e "${BLUE}4. Upload the signed AAB to Google Play Console${NC}"
    
    echo -e "${RED}⚠️  IMPORTANT: Keep your keystore file and passwords secure!${NC}"
    echo -e "${RED}⚠️  Backup your keystore - losing it means you can't update your app!${NC}"
    
else
    echo -e "${RED}❌ Failed to create keystore${NC}"
    exit 1
fi
