// Database Migration Runner
// This script will run the migration against your Supabase database

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

// Load environment variables
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // You'll need to add this

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing Supabase credentials');
  console.log('Please ensure you have:');
  console.log('- VITE_SUPABASE_URL in your .env.local');
  console.log('- SUPABASE_SERVICE_ROLE_KEY in your .env.local (get this from Supabase dashboard)');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function runMigration() {
  try {
    console.log('🚀 Starting database migration...');
    
    // Read the migration file
    const migrationPath = path.join(process.cwd(), 'supabase', 'migrations', '20250622130600_add_new_features.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('📄 Migration file loaded');
    console.log('📊 Executing migration...');
    
    // Execute the migration
    const { data, error } = await supabase.rpc('exec_sql', {
      sql: migrationSQL
    });
    
    if (error) {
      console.error('❌ Migration failed:', error);
      return;
    }
    
    console.log('✅ Migration completed successfully!');
    console.log('📋 New tables and features added:');
    console.log('   • user_push_tokens - For push notifications');
    console.log('   • group_meetings - For meeting management');
    console.log('   • scheduled_notifications - For automated reminders');
    console.log('   • group_documents - For document storage');
    console.log('   • mpesa_transactions - For M-Pesa payments');
    console.log('   • report_templates - For advanced reporting');
    console.log('   • contribution_reminders - For contribution alerts');
    console.log('   • Enhanced RLS policies and functions');
    
  } catch (error) {
    console.error('❌ Error running migration:', error);
  }
}

runMigration();
