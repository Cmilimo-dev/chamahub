# Phase D: Production Readiness Guide

## Overview
This guide covers the complete production setup for ChamaHub, including environment configuration, app signing, performance optimization, security audits, and deployment preparation.

## 1. Environment Setup

### Production Environment Variables
Create `.env.production` with production values:
```bash
# Supabase Production
VITE_SUPABASE_URL=https://your-prod-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_production_anon_key

# M-Pesa Production (Safaricom)
VITE_MPESA_CONSUMER_KEY=your_production_consumer_key
VITE_MPESA_CONSUMER_SECRET=your_production_consumer_secret
VITE_MPESA_SHORTCODE=your_production_shortcode
VITE_MPESA_PASSKEY=your_production_passkey
VITE_MPESA_ENVIRONMENT=production

# Firebase Production
VITE_FIREBASE_API_KEY=your_production_firebase_api_key
VITE_FIREBASE_PROJECT_ID=your_production_firebase_project_id
VITE_FIREBASE_MESSAGING_SENDER_ID=your_production_sender_id
VITE_FIREBASE_APP_ID=your_production_app_id
VITE_FIREBASE_VAPID_KEY=your_production_vapid_key

# App Configuration
VITE_APP_ENV=production
VITE_APP_VERSION=1.0.0
VITE_SENTRY_DSN=your_sentry_dsn_for_error_tracking
```

### Supabase Production Setup
1. Create production Supabase project
2. Run database migration
3. Configure Row Level Security policies
4. Set up database backups
5. Configure API rate limiting

## 2. Android App Signing

### Generate Signing Key
```bash
keytool -genkey -v -keystore chamahub-release-key.keystore -alias chamahub -keyalg RSA -keysize 2048 -validity 10000
```

### Keystore Configuration
Update `android/app/build.gradle`:
```gradle
android {
    signingConfigs {
        release {
            keyAlias 'chamahub'
            keyPassword 'your_key_password'
            storeFile file('chamahub-release-key.keystore')
            storePassword 'your_keystore_password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

## 3. Performance Optimization

### Bundle Optimization
- Code splitting implemented ✓
- Lazy loading implemented ✓
- Tree shaking enabled ✓
- Asset optimization needed

### Caching Strategy
- Service worker caching ✓
- API response caching ✓
- Static asset caching ✓
- Database query optimization needed

### Monitoring
- Performance monitoring implemented ✓
- Error tracking setup needed
- Analytics setup needed

## 4. Security Audit

### Checklist
- [ ] API keys secured in environment variables
- [ ] Database RLS policies tested
- [ ] Input validation implemented
- [ ] HTTPS enforced
- [ ] Content Security Policy configured
- [ ] Authentication flows secured
- [ ] File upload security
- [ ] Rate limiting configured

## 5. Testing

### Pre-Production Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass
- [ ] Performance tests pass
- [ ] Security tests pass
- [ ] Mobile responsiveness tested
- [ ] Offline functionality tested
- [ ] Push notifications tested
- [ ] M-Pesa integration tested

## 6. Deployment Pipeline

### Build Commands
```bash
# Web production build
npm run build

# Android production build
npm run build:android:prod

# Generate signed APK
cd android && ./gradlew assembleRelease

# Generate signed AAB (for Play Store)
cd android && ./gradlew bundleRelease
```

### Deployment Checklist
- [ ] Environment variables set
- [ ] Database migrated
- [ ] SSL certificates configured
- [ ] CDN configured
- [ ] Error tracking configured
- [ ] Monitoring dashboards set up
- [ ] Backup procedures tested
- [ ] Rollback plan prepared

## 7. Post-Deployment

### Monitoring
- Application performance
- Error rates
- User engagement
- System resources
- Database performance

### Maintenance
- Regular security updates
- Database maintenance
- Performance optimization
- Feature updates
- Bug fixes

## Next Steps
1. Set up production Supabase project
2. Configure app signing
3. Run security audit
4. Set up error tracking
5. Configure monitoring
6. Test production build
7. Deploy to production
