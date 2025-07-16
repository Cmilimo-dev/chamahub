// Test script to diagnose login issues
import fetch from 'node-fetch';

const testLogin = async (email, password) => {
    try {
        console.log(`\n=== Testing login for ${email} ===`);
        console.log('Password:', password);
        console.log('Password length:', password.length);
        console.log('Password hash:', Buffer.from(password).toString('base64'));
        
        const response = await fetch('http://localhost:4000/api/auth/signin', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ email, password }),
        });
        
        console.log('Response status:', response.status);
        console.log('Response headers:', Object.fromEntries(response.headers));
        
        if (response.ok) {
            const data = await response.json();
            console.log('✅ Login successful!');
            console.log('User data:', data);
            return true;
        } else {
            const error = await response.json();
            console.log('❌ Login failed!');
            console.log('Error:', error);
            return false;
        }
    } catch (error) {
        console.log('❌ Network error!');
        console.log('Error:', error.message);
        return false;
    }
};

// Test all available users
const testUsers = [
    { email: 'admin@chamahub.com', password: 'newpassword123' },
    { email: 'secretary@chamahub.com', password: 'password123' },
    { email: 'treasurer@chamahub.com', password: 'password123' },
    { email: 'test@example.com', password: 'password123' },
    { email: 'user1@chamahub.com', password: 'password123' },
    { email: 'user2@chamahub.com', password: 'password123' },
];

const runTests = async () => {
    console.log('🔍 Running login diagnostic tests...\n');
    
    for (const user of testUsers) {
        await testLogin(user.email, user.password);
    }
    
    console.log('\n🔍 Testing with incorrect credentials...');
    await testLogin('admin@chamahub.com', 'wrongpassword');
    await testLogin('nonexistent@example.com', 'password123');
    
    console.log('\n✅ All tests completed!');
};

runTests().catch(console.error);
