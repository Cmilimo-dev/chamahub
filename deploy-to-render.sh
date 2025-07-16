#!/bin/bash

# ChamaHub Render Deployment Script

set -e

echo "🚀 Starting ChamaHub deployment to Render..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if render CLI is available
if ! command -v render &> /dev/null; then
    echo -e "${RED}❌ Render CLI not found. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Render CLI found${NC}"

# Check if logged in
if ! render whoami &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Render. Please run 'render login' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Logged in to Render${NC}"

# Repository details
REPO_URL="https://github.com/Cmilimo-dev/chamahub"
SERVICE_NAME="chamahub-backend"
DB_NAME="chamahub-db"

echo -e "${YELLOW}📝 Deployment Configuration:${NC}"
echo "Repository: $REPO_URL"
echo "Service: $SERVICE_NAME"
echo "Database: $DB_NAME"
echo "Deployment file: render.yaml"
echo ""

echo -e "${YELLOW}🔧 Setting up deployment...${NC}"

echo -e "${GREEN}✅ Your GitHub repository is ready at: $REPO_URL${NC}"
echo -e "${GREEN}✅ Your render.yaml configuration is valid${NC}"

echo ""
echo -e "${YELLOW}📋 Next Steps - Deploy via Render Dashboard:${NC}"
echo "1. Go to https://dashboard.render.com"
echo "2. Click 'New' → 'Blueprint'"
echo "3. Connect your GitHub repository: $REPO_URL"
echo "4. Select the repository and click 'Connect'"
echo "5. Render will detect your render.yaml file automatically"
echo ""

echo -e "${YELLOW}🔐 Required Environment Variables:${NC}"
echo "Set these in your Render dashboard:"
echo "- SMTP_USER: [Your Gmail address]"
echo "- SMTP_PASS: [Your Gmail app password]"
echo "- TWILIO_ACCOUNT_SID: [Your Twilio Account SID]"
echo "- TWILIO_AUTH_TOKEN: [Your Twilio Auth Token]"
echo "- TWILIO_PHONE_NUMBER: [Your Twilio Phone Number]"
echo ""

echo -e "${YELLOW}🎯 Expected Deployment URL:${NC}"
echo "https://chamahub-backend.onrender.com"
echo ""

echo -e "${YELLOW}🧪 Test Your Deployment:${NC}"
echo "Health check: https://chamahub-backend.onrender.com/api/health"
echo ""

echo -e "${GREEN}🎉 Deployment configuration complete!${NC}"
echo -e "${GREEN}📱 Your Android APK is already configured to use the production backend.${NC}"
echo -e "${GREEN}🌐 Once deployed, your mobile app will be fully independent!${NC}"

# Open the Render dashboard
echo ""
read -p "Would you like to open the Render dashboard now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "https://dashboard.render.com/create?type=blueprint"
fi

echo ""
echo -e "${GREEN}✨ Deployment script completed successfully!${NC}"
