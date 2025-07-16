# ChamaHub Production Deployment Checklist

## Pre-Deployment Checklist

### 1. Environment Setup
- [ ] Create production Supabase project
- [ ] Set up production Firebase project
- [ ] Configure M-Pesa production credentials
- [ ] Set up Sentry project for error tracking
- [ ] Create `.env.production` with all production keys
- [ ] Verify all environment variables are set

### 2. Database Setup
- [ ] Run database migration (see MIGRATION_GUIDE.md)
- [ ] Verify all tables are created
- [ ] Test RLS policies
- [ ] Set up database backups
- [ ] Configure connection pooling

### 3. Security Audit
- [ ] Run security audit: `npm run security:audit`
- [ ] Fix any critical security issues
- [ ] Verify no secrets in code
- [ ] Test authentication flows
- [ ] Verify input validation
- [ ] Test file upload security

### 4. App Signing (Android)
- [ ] Generate release keystore
- [ ] Configure signing in build.gradle
- [ ] Test signed build locally
- [ ] Store keystore securely

### 5. Performance Optimization
- [ ] Run bundle analysis: `npm run build:analyze`
- [ ] Optimize large chunks
- [ ] Test loading performance
- [ ] Verify service worker caching
- [ ] Test offline functionality

### 6. Testing
- [ ] Run all unit tests
- [ ] Test critical user flows
- [ ] Test on multiple devices
- [ ] Test push notifications
- [ ] Test M-Pesa integration (sandbox first)
- [ ] Test offline/online scenarios
- [ ] Verify camera/QR functionality

## Deployment Steps

### 1. Prepare Build
```bash
# Clean everything
npm run clean:all && npm install

# Run security checks
npm run security:check

# Build for production
npm run build:production
```

### 2. Deploy Web App
```bash
# Deploy to your hosting platform
# Example for Netlify:
npm run build:prod
# Upload dist/ folder to Netlify

# Example for Vercel:
vercel --prod
```

### 3. Build Android App
```bash
# Generate signed APK
npm run android:build:prod

# Generate signed AAB for Play Store
npm run android:build:bundle
```

### 4. Upload to Stores

#### Google Play Store
- [ ] Upload signed AAB
- [ ] Complete store listing
- [ ] Add screenshots
- [ ] Set pricing and distribution
- [ ] Submit for review

#### Other App Stores (if applicable)
- [ ] Samsung Galaxy Store
- [ ] Amazon Appstore
- [ ] Direct APK distribution

## Post-Deployment

### 1. Monitoring Setup
- [ ] Configure Sentry dashboards
- [ ] Set up performance alerts
- [ ] Configure error notifications
- [ ] Monitor database performance
- [ ] Set up uptime monitoring

### 2. Analytics
- [ ] Configure user analytics
- [ ] Set up conversion tracking
- [ ] Monitor user engagement
- [ ] Track feature usage

### 3. Security Monitoring
- [ ] Monitor API usage
- [ ] Set up rate limiting alerts
- [ ] Review authentication logs
- [ ] Monitor for security incidents

### 4. Backup and Recovery
- [ ] Verify database backups
- [ ] Test recovery procedures
- [ ] Document rollback process
- [ ] Set up automated backups

## Production Environment Variables

Create `.env.production` with:

```bash
# Supabase Production
VITE_SUPABASE_URL=https://your-prod-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_production_anon_key

# M-Pesa Production
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

# Error Tracking
VITE_SENTRY_DSN=your_sentry_dsn

# App Configuration
VITE_APP_ENV=production
VITE_APP_VERSION=1.0.0
```

## Key Commands for Production

```bash
# Security and build
npm run deploy:prepare

# Android production build
npm run deploy:android

# Manual steps
npm run security:audit
npm run build:prod
npm run android:build:bundle
```

## Rollback Plan

In case issues are found post-deployment:

1. **Web App**: Revert to previous deployment
2. **Database**: Use backup to restore if needed
3. **Mobile App**: Pull from stores if critical issues
4. **Monitor**: Watch error rates and user reports

## Support and Maintenance

- Monitor Sentry for errors
- Check Supabase dashboard for database health
- Review app store ratings and feedback
- Plan regular security updates
- Schedule performance optimizations

---

**Important**: Test everything in staging environment first!
**Critical**: Keep production credentials secure and never commit them to version control.
