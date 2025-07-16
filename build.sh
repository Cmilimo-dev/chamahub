#!/bin/bash

# Build script for ChamaHub Backend

echo "🚀 Starting ChamaHub Backend deployment build..."

# Copy backend-specific package.json
echo "📦 Setting up backend package.json..."
cp backend-package.json package.json

# Install dependencies
echo "📥 Installing dependencies..."
npm install

# Verify server file exists
if [ ! -f "server-postgres.js" ]; then
    echo "❌ server-postgres.js not found!"
    exit 1
fi

echo "✅ Build completed successfully!"
echo "🔧 Backend is ready to start with: node server-postgres.js"
