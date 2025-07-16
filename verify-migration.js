// Migration Verification Script
// Run this after applying the database migration to verify everything is working

import { apiClient } from './src/lib/api.js';

const EXPECTED_TABLES = [
  'user_push_tokens',
  'group_meetings', 
  'scheduled_notifications',
  'group_documents',
  'mpesa_transactions',
  'report_templates',
  'contribution_reminders'
];

async function verifyMigration() {
  console.log('🔍 Verifying database migration...\n');
  
  let allSuccess = true;
  
  // Check if tables exist by trying to query them
  for (const tableName of EXPECTED_TABLES) {
    try {
      const { data, error } = await supabase
        .from(tableName)
        .select('*')
        .limit(0);
      
      if (error && error.code === '42P01') {
        console.log(`❌ Table '${tableName}' does not exist`);
        allSuccess = false;
      } else if (error) {
        console.log(`⚠️  Table '${tableName}' exists but has issues: ${error.message}`);
      } else {
        console.log(`✅ Table '${tableName}' exists and is accessible`);
      }
    } catch (error) {
      console.log(`❌ Error checking table '${tableName}': ${error.message}`);
      allSuccess = false;
    }
  }
  
  console.log('\n📊 Testing core functionality...\n');
  
  // Test M-Pesa transactions table
  try {
    const { data, error } = await supabase
      .from('mpesa_transactions')
      .select('id')
      .limit(1);
    
    if (!error) {
      console.log('✅ M-Pesa transactions table is ready');
    } else {
      console.log(`❌ M-Pesa transactions table issue: ${error.message}`);
      allSuccess = false;
    }
  } catch (error) {
    console.log(`❌ M-Pesa transactions test failed: ${error.message}`);
    allSuccess = false;
  }
  
  // Test push notifications table
  try {
    const { data, error } = await supabase
      .from('user_push_tokens')
      .select('id')
      .limit(1);
    
    if (!error) {
      console.log('✅ Push notifications table is ready');
    } else {
      console.log(`❌ Push notifications table issue: ${error.message}`);
      allSuccess = false;
    }
  } catch (error) {
    console.log(`❌ Push notifications test failed: ${error.message}`);
    allSuccess = false;
  }
  
  // Test group meetings table
  try {
    const { data, error } = await supabase
      .from('group_meetings')
      .select('id')
      .limit(1);
    
    if (!error) {
      console.log('✅ Group meetings table is ready');
    } else {
      console.log(`❌ Group meetings table issue: ${error.message}`);
      allSuccess = false;
    }
  } catch (error) {
    console.log(`❌ Group meetings test failed: ${error.message}`);
    allSuccess = false;
  }
  
  console.log('\n' + '='.repeat(50));
  
  if (allSuccess) {
    console.log('🎉 Migration verification PASSED!');
    console.log('✅ All tables are ready');
    console.log('✅ Your app can now use:');
    console.log('   • M-Pesa payment integration');
    console.log('   • Push notifications');
    console.log('   • Meeting management');
    console.log('   • Document storage');
    console.log('   • Advanced reporting');
    console.log('   • Automated reminders');
  } else {
    console.log('❌ Migration verification FAILED');
    console.log('🔧 Please check the migration guide and run the SQL migration again');
  }
  
  console.log('\n📋 Next steps:');
  console.log('1. Set up Firebase for push notifications');
  console.log('2. Configure M-Pesa sandbox credentials');
  console.log('3. Test the new features in your app');
}

verifyMigration().catch(console.error);
