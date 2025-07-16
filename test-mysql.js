import mysql from 'mysql2/promise';

const config = {
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'chamahub',
  port: 3306
};

async function testConnection() {
  try {
    console.log('Testing MySQL connection...');
    const connection = await mysql.createConnection(config);
    
    console.log('✅ Connected to MySQL successfully!');
    
    // Test basic query
    const [rows] = await connection.execute('SELECT COUNT(*) as count FROM users');
    console.log(`✅ Found ${rows[0].count} users in database`);
    
    // Test relationship query
    const [groups] = await connection.execute(`
      SELECT cg.name, COUNT(gm.id) as member_count 
      FROM chama_groups cg 
      LEFT JOIN group_members gm ON cg.id = gm.group_id 
      GROUP BY cg.id, cg.name
    `);
    console.log(`✅ Found ${groups.length} groups with members:`, groups);
    
    await connection.end();
    console.log('✅ MySQL test completed successfully!');
    
  } catch (error) {
    console.error('❌ MySQL connection failed:', error);
    process.exit(1);
  }
}

testConnection();
