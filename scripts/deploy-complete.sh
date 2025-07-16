#!/bin/bash

echo "🚀 ChamaHub Complete Deployment Script"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}
   ██████╗██╗  ██╗ █████╗ ███╗   ███╗ █████╗ ██╗  ██╗██╗   ██╗██████╗ 
  ██╔════╝██║  ██║██╔══██╗████╗ ████║██╔══██╗██║  ██║██║   ██║██╔══██╗
  ██║     ███████║███████║██╔████╔██║███████║███████║██║   ██║██████╔╝
  ██║     ██╔══██║██╔══██║██║╚██╔╝██║██╔══██║██╔══██║██║   ██║██╔══██╗
  ╚██████╗██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╔╝██████╔╝
   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ 
${NC}"

# Create deployment directory
DEPLOY_DIR="deployment-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEPLOY_DIR"

echo -e "${YELLOW}📦 Creating deployment package...${NC}"

# 1. Build Web Application
echo -e "${BLUE}1. Building web application...${NC}"
npm run build:prod

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Web build failed${NC}"
    exit 1
fi

# 2. Build Android App
echo -e "${BLUE}2. Building Android application...${NC}"
npm run android:build:bundle

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Android build failed${NC}"
    exit 1
fi

# 3. Copy deployment files
echo -e "${BLUE}3. Copying deployment files...${NC}"

# Web build
cp -r dist "$DEPLOY_DIR/web-build"

# Android builds
mkdir -p "$DEPLOY_DIR/android"
cp android/app/build/outputs/apk/debug/app-debug.apk "$DEPLOY_DIR/android/" 2>/dev/null || echo "Debug APK not found"
cp android/app/build/outputs/bundle/release/app-release.aab "$DEPLOY_DIR/android/" 2>/dev/null || echo "Release AAB not found"

# App Store assets
cp -r assets/app-store "$DEPLOY_DIR/" 2>/dev/null || echo "App store assets not found"

# 4. Create deployment documentation
echo -e "${BLUE}4. Creating deployment documentation...${NC}"

cat > "$DEPLOY_DIR/DEPLOYMENT_GUIDE.md" << 'EOF'
# ChamaHub Deployment Guide

## Package Contents

### Web Application
- `web-build/` - Built web application ready for hosting
- Deploy to: Vercel, Netlify, or any static hosting service

### Android Application
- `android/app-debug.apk` - Debug version for testing
- `android/app-release.aab` - Production version for Google Play Store

### App Store Assets
- `app-store/android/` - Google Play Store assets
- `app-store/ios/` - Apple App Store assets (when iOS is built)
- `app-store/screenshots/` - App screenshots
- `app-store/app-description.md` - App store descriptions
- `app-store/privacy-policy.md` - Privacy policy template

## Deployment Steps

### 1. Web Application Deployment

#### Option A: Vercel (Recommended)
```bash
npm install -g vercel
vercel --prod
```

#### Option B: Netlify
```bash
npm install -g netlify-cli
netlify deploy --prod --dir=web-build
```

#### Option C: Traditional Hosting
Upload the `web-build/` folder to your web server

### 2. Android Deployment

#### Google Play Store
1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app
3. Upload `android/app-release.aab`
4. Fill in app details using `app-store/app-description.md`
5. Upload assets from `app-store/android/`
6. Submit for review

#### Direct Distribution
1. Share `android/app-debug.apk` for testing
2. Users need to enable "Unknown Sources" in Android settings

### 3. Backend Deployment

#### Option A: Railway
```bash
npm install -g @railway/cli
railway login
railway deploy
```

#### Option B: Heroku
```bash
heroku create chamahub-api
git push heroku main
```

#### Option C: VPS/Cloud Server
1. Install Node.js and MySQL
2. Upload project files
3. Configure environment variables
4. Run `npm install && node server.js`

### 4. Database Setup

#### Production Database
1. Set up MySQL database (AWS RDS, PlanetScale, etc.)
2. Run migration scripts from `migrations/` folder
3. Update connection strings in environment variables

#### Environment Variables
```
DATABASE_URL=mysql://username:password@host:port/database
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
```

### 5. Domain and SSL
1. Purchase domain name
2. Configure DNS records
3. Set up SSL certificates (automatic with most hosting providers)

## Post-Deployment

### Testing
- Test all app features
- Verify payment integrations
- Check email/SMS notifications
- Test on multiple devices

### Monitoring
- Set up error tracking (Sentry)
- Configure analytics
- Monitor performance
- Set up backup strategies

### Maintenance
- Regular updates
- Security patches
- Database backups
- Monitor user feedback

## Support

For deployment support:
- Email: support@chamahub.com
- Documentation: [Your docs URL]
- Issues: [Your GitHub issues URL]

## Security Notes

- Never commit sensitive keys to version control
- Use environment variables for all secrets
- Enable 2FA on all accounts
- Regular security audits
- Keep dependencies updated

EOF

# 5. Create environment template
cat > "$DEPLOY_DIR/env-template.txt" << 'EOF'
# ChamaHub Environment Variables Template
# Copy this to .env and fill in your actual values

# Database Configuration
DATABASE_URL=mysql://username:password@host:port/chamahub

# Email Configuration (Gmail example)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# SMS Configuration (Twilio)
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# App Configuration
NODE_ENV=production
PORT=4000
JWT_SECRET=your-jwt-secret-key

# Frontend URL (for CORS)
FRONTEND_URL=https://your-domain.com

# File Upload (if using cloud storage)
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_BUCKET_NAME=your-s3-bucket

# Push Notifications (Firebase)
FIREBASE_SERVER_KEY=your-firebase-server-key

# Analytics (Optional)
GOOGLE_ANALYTICS_ID=your-ga-id
SENTRY_DSN=your-sentry-dsn
EOF

# 6. Create quick start script
cat > "$DEPLOY_DIR/quick-start.sh" << 'EOF'
#!/bin/bash

echo "🚀 ChamaHub Quick Start"

# Check if required tools are installed
command -v node >/dev/null 2>&1 || { echo "Node.js is required but not installed. Aborting." >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm is required but not installed. Aborting." >&2; exit 1; }

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Set up environment
if [ ! -f .env ]; then
    echo "📝 Creating environment file..."
    cp env-template.txt .env
    echo "⚠️  Please edit .env with your actual values"
fi

# Run database migrations
echo "🗄️  Running database migrations..."
node run-migration.js

# Start server
echo "🚀 Starting server..."
npm start

EOF

chmod +x "$DEPLOY_DIR/quick-start.sh"

# 7. Create package info
cat > "$DEPLOY_DIR/package-info.json" << EOF
{
  "name": "ChamaHub",
  "version": "1.0.0",
  "description": "Financial management app for chama groups",
  "package_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "build_info": {
    "web": "$(ls -la web-build/index.html 2>/dev/null | awk '{print $5}' || echo 'not found') bytes",
    "android_debug": "$(ls -la android/app-debug.apk 2>/dev/null | awk '{print $5}' || echo 'not found') bytes",
    "android_release": "$(ls -la android/app-release.aab 2>/dev/null | awk '{print $5}' || echo 'not found') bytes"
  },
  "deployment_targets": {
    "web": ["Vercel", "Netlify", "Static hosting"],
    "android": ["Google Play Store", "Direct distribution"],
    "backend": ["Railway", "Heroku", "VPS"]
  }
}
EOF

# 8. Create deployment summary
echo -e "${GREEN}✅ Deployment package created successfully!${NC}"
echo -e "${BLUE}📂 Package location: $DEPLOY_DIR${NC}"
echo -e "${BLUE}📊 Package size: $(du -sh $DEPLOY_DIR | cut -f1)${NC}"

echo -e "${YELLOW}📋 Package contents:${NC}"
echo -e "${BLUE}  • Web application build${NC}"
echo -e "${BLUE}  • Android APK and AAB files${NC}"
echo -e "${BLUE}  • App store assets and metadata${NC}"
echo -e "${BLUE}  • Deployment documentation${NC}"
echo -e "${BLUE}  • Environment templates${NC}"
echo -e "${BLUE}  • Quick start script${NC}"

echo -e "${YELLOW}🚀 Ready to deploy:${NC}"
echo -e "${GREEN}  1. Web: Upload to Vercel/Netlify${NC}"
echo -e "${GREEN}  2. Android: Upload AAB to Play Store${NC}"
echo -e "${GREEN}  3. Backend: Deploy to Railway/Heroku${NC}"
echo -e "${GREEN}  4. Database: Set up production MySQL${NC}"

echo -e "${PURPLE}🎉 ChamaHub deployment package ready!${NC}"
echo -e "${BLUE}📖 Read $DEPLOY_DIR/DEPLOYMENT_GUIDE.md for detailed instructions${NC}"
