# Database Migration Guide

## 🗄️ Phase C: Running Database Migration

This guide will help you apply the database migration to add all the new features to your ChamaHub app.

---

## Step 1: Access Supabase SQL Editor

1. **Go to Supabase Dashboard**: https://app.supabase.com/project/horacqblqojxtomwxkfh
2. **Navigate to SQL Editor**: Click on "SQL Editor" in the left sidebar
3. **Create New Query**: Click "New Query" button

---

## Step 2: Run the Migration

1. **Copy Migration Content**: Copy the entire content from:
   ```
   supabase/migrations/20250622130600_add_new_features.sql
   ```

2. **Paste in SQL Editor**: Paste the migration SQL into the query editor

3. **Execute Migration**: Click "Run" button to execute the migration

---

## Step 3: Verify Migration Success

After running the migration, run these verification queries to ensure everything was created successfully:

### Check New Tables
```sql
-- Verify all new tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'user_push_tokens',
  'group_meetings', 
  'scheduled_notifications',
  'group_documents',
  'mpesa_transactions',
  'report_templates',
  'contribution_reminders'
);
```

### Check Table Structures
```sql
-- Check user_push_tokens table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_push_tokens';

-- Check mpesa_transactions table  
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'mpesa_transactions';

-- Check group_meetings table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'group_meetings';
```

### Check RLS Policies
```sql
-- Verify RLS policies were created
SELECT schemaname, tablename, policyname, roles
FROM pg_policies 
WHERE tablename IN (
  'user_push_tokens',
  'group_meetings', 
  'scheduled_notifications',
  'group_documents',
  'mpesa_transactions',
  'report_templates',
  'contribution_reminders'
);
```

### Check Functions
```sql
-- Verify new function was created
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'get_group_financial_summary';
```

---

## Step 4: Test New Features

After migration, you can test the new functionality:

### Test M-Pesa Integration
```sql
-- Insert a test M-Pesa transaction (replace UUIDs with real ones)
INSERT INTO mpesa_transactions (
  user_id,
  group_id, 
  amount,
  phone_number,
  status
) VALUES (
  'your-user-id',
  'your-group-id',
  1000,
  '254712345678',
  'pending'
);
```

### Test Push Notification Tokens
```sql
-- Insert a test push token
INSERT INTO user_push_tokens (
  user_id,
  token,
  platform
) VALUES (
  'your-user-id',
  'test-token-123',
  'web'
);
```

### Test Group Meetings
```sql
-- Insert a test meeting
INSERT INTO group_meetings (
  group_id,
  title,
  description,
  meeting_date,
  meeting_time,
  created_by,
  status
) VALUES (
  'your-group-id',
  'Monthly Chama Meeting',
  'Regular monthly meeting',
  CURRENT_DATE + INTERVAL '7 days',
  '14:00',
  'your-user-id',
  'scheduled'
);
```

---

## Step 5: Cleanup (Optional)

Remove the migration runner script if you don't need it:
```bash
rm run-migration.js
```

---

## 🎉 What You'll Get After Migration

✅ **M-Pesa Integration Ready** - Complete payment processing tables  
✅ **Push Notifications** - Token storage and notification scheduling  
✅ **Meeting Management** - Full meeting lifecycle support  
✅ **Document Storage** - File upload and management system  
✅ **Advanced Reporting** - Enhanced analytics and financial summaries  
✅ **Automated Reminders** - Contribution and meeting alerts  
✅ **Enhanced Security** - Row Level Security policies for all new features  

---

## Troubleshooting

### Common Issues:

1. **Permission Denied**: Make sure you're logged in as a Supabase admin
2. **Duplicate Table Error**: Some tables might already exist - this is usually safe to ignore
3. **Function Creation Error**: Drop existing functions first if needed:
   ```sql
   DROP FUNCTION IF EXISTS public.get_group_financial_summary;
   ```

### Need Help?
If you encounter any issues:
1. Check the Supabase logs in the dashboard
2. Verify your database permissions
3. Run the verification queries above to see what succeeded

---

## Next Steps After Migration

Once migration is complete, you can:
1. ✅ Test M-Pesa payments in your app
2. ✅ Enable push notifications
3. ✅ Schedule group meetings
4. ✅ Upload documents
5. ✅ Generate advanced reports
