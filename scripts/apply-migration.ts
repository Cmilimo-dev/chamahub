import { supabase } from '../src/integrations/supabase/client';
import * as fs from 'fs';
import * as path from 'path';

async function applyMigration() {
  try {
    console.log('📚 Reading migration file...');
    
    const migrationPath = path.join(__dirname, '../migrations/add_form_submitted_to_membership_requests.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('🚀 Applying migration to add form_submitted column...');
    
    // Split the SQL into individual statements
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    for (const statement of statements) {
      if (statement.trim()) {
        console.log(`Executing: ${statement.substring(0, 50)}...`);
        const { error } = await supabase.rpc('exec_sql', { query: statement });
        
        if (error) {
          // If exec_sql doesn't exist, try direct execution (this might not work due to permissions)
          console.warn('exec_sql RPC not available, trying direct execution...');
          throw error;
        }
      }
    }
    
    console.log('✅ Migration applied successfully!');
    console.log('🔍 Verifying the changes...');
    
    // Test that the column exists by trying to select it
    const { data, error } = await supabase
      .from('membership_requests')
      .select('form_submitted')
      .limit(1);
    
    if (error) {
      throw new Error(`Verification failed: ${error.message}`);
    }
    
    console.log('✅ Verification successful! The form_submitted column is now available.');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    console.log('\n📝 Manual steps required:');
    console.log('1. Go to your Supabase dashboard');
    console.log('2. Navigate to the SQL Editor');
    console.log('3. Run the following SQL:');
    console.log('\n' + fs.readFileSync(path.join(__dirname, '../migrations/add_form_submitted_to_membership_requests.sql'), 'utf8'));
    process.exit(1);
  }
}

// Only run if this file is executed directly
if (require.main === module) {
  applyMigration();
}
