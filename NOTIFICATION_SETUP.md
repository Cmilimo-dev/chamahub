# Email and SMS Notification Setup Guide

## Overview
The system now supports sending email and SMS invitations to members when they are invited to join a group. This guide will help you set up the necessary credentials.

## Current Status
✅ **Backend Implementation**: Complete
✅ **Frontend Integration**: Complete
✅ **Database Schema**: Complete
❌ **Email Credentials**: Not configured
❌ **SMS Credentials**: Not configured

## Setting Up Email Notifications

### Option 1: Gmail (Recommended for testing)
1. Create a Gmail account or use an existing one
2. Enable 2-factor authentication
3. Generate an App Password:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a new app password for "Mail"
4. Update your `.env` file:
   ```
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-generated-app-password
   ```

### Option 2: Other Email Providers
- **Outlook**: `smtp-mail.outlook.com`, port 587
- **Yahoo**: `smtp.mail.yahoo.com`, port 587
- **Custom SMTP**: Use your hosting provider's SMTP settings

## Setting Up SMS Notifications

### Twilio (Recommended)
1. Sign up at [twilio.com](https://www.twilio.com)
2. Get your Account SID and Auth Token from the Console
3. Purchase a phone number or use the trial number
4. Update your `.env` file:
   ```
   TWILIO_ACCOUNT_SID=your-account-sid
   TWILIO_AUTH_TOKEN=your-auth-token
   TWILIO_PHONE_NUMBER=+1234567890
   ```

### Alternative SMS Providers
- **AWS SNS**: More complex setup, good for production
- **Vonage (Nexmo)**: Similar to Twilio
- **MessageBird**: Another good option

## Environment Configuration

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Update the `.env` file with your credentials:
   ```
   # Email Configuration
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your-actual-email@gmail.com
   SMTP_PASS=your-actual-app-password
   
   # SMS Configuration
   TWILIO_ACCOUNT_SID=your-actual-account-sid
   TWILIO_AUTH_TOKEN=your-actual-auth-token
   TWILIO_PHONE_NUMBER=your-actual-phone-number
   ```

3. Restart the server:
   ```bash
   pkill -f "node server.js"
   nohup node server.js > server.log 2>&1 &
   ```

## Testing the Setup

1. **Create a test group** with member invitations
2. **Check the server logs** for any errors:
   ```bash
   tail -f server.log
   ```
3. **Verify emails are sent** to the invited members
4. **Verify SMS messages are sent** if phone numbers are provided

## Troubleshooting

### Email Issues
- **Gmail blocking**: Make sure you're using an App Password, not your regular password
- **SMTP errors**: Check your SMTP settings and credentials
- **Firewall**: Ensure port 587 is open

### SMS Issues
- **Twilio trial**: Trial accounts can only send to verified phone numbers
- **Phone number format**: Use international format (+1234567890)
- **Balance**: Check your Twilio account balance

### General Issues
- **Environment variables**: Ensure `.env` file is in the project root
- **Server restart**: Always restart the server after changing `.env`
- **Console logs**: Check browser console and server logs for errors

## Security Notes

1. **Never commit** your `.env` file to version control
2. **Use environment variables** in production
3. **Rotate credentials** regularly
4. **Monitor usage** to prevent abuse

## Production Considerations

1. **Email deliverability**: Use a dedicated email service like SendGrid or Mailgun
2. **SMS costs**: Monitor SMS usage to control costs
3. **Rate limiting**: Implement rate limiting to prevent spam
4. **Compliance**: Ensure compliance with email and SMS regulations (CAN-SPAM, GDPR, etc.)

## Current API Endpoints

- `POST /api/invitations/send` - Send individual invitation
- `GET /api/invitations/:token` - Get invitation details
- `POST /api/invitations/:token/accept` - Accept invitation

## Next Steps

1. Set up your email and SMS credentials
2. Test the functionality with real invitations
3. Monitor the server logs for any issues
4. Consider implementing additional features like:
   - Invitation resending
   - Bulk invitation management
   - Notification preferences
   - Invitation tracking and analytics
