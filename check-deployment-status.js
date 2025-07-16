#!/usr/bin/env node

// Quick deployment status checker for ChamaHub Backend

const API_BASE_URL = 'https://chamahub-backend.onrender.com/api';

async function checkDeploymentStatus() {
  console.log('🔍 Checking ChamaHub Backend Deployment Status...\n');
  
  try {
    console.log(`📍 Testing: ${API_BASE_URL}/health`);
    
    const response = await fetch(`${API_BASE_URL}/health`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (response.ok) {
      const data = await response.json();
      console.log('✅ DEPLOYMENT SUCCESSFUL!');
      console.log('📊 Status:', data.status);
      console.log('🗄️  Database:', data.database);
      console.log('⏰ Timestamp:', data.timestamp);
      console.log('\n🎉 Your backend is live and ready!');
      console.log('\n📋 Next steps:');
      console.log('1. Run: node test-deployment.js (to test all endpoints)');
      console.log('2. Update frontend API URL if needed');
      console.log('3. Configure environment variables in Render dashboard');
      
      return true;
    } else {
      console.log('❌ DEPLOYMENT FAILED or NOT READY');
      console.log('Status:', response.status);
      console.log('Response:', await response.text());
      return false;
    }
  } catch (error) {
    console.log('🚨 CONNECTION ERROR:');
    console.log('- Backend might still be deploying');
    console.log('- Check Render dashboard for deployment logs');
    console.log('- Error details:', error.message);
    return false;
  }
}

// Auto-retry every 30 seconds if deployment is not ready
async function monitorDeployment() {
  const maxRetries = 20; // 10 minutes max
  let retries = 0;
  
  while (retries < maxRetries) {
    const isReady = await checkDeploymentStatus();
    
    if (isReady) {
      break;
    }
    
    retries++;
    console.log(`\n⏳ Retrying in 30 seconds... (${retries}/${maxRetries})`);
    await new Promise(resolve => setTimeout(resolve, 30000));
  }
  
  if (retries >= maxRetries) {
    console.log('\n⚠️  Deployment taking longer than expected');
    console.log('Please check the Render dashboard for deployment status');
  }
}

// Run the status checker
monitorDeployment().catch(console.error);
