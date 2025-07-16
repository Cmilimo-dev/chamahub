#!/usr/bin/env node

// Test script to verify network connectivity for Android emulator
import https from 'https';
import http from 'http';

// Test URLs
const testUrls = [
  'http://localhost:4000/api/users',
  'http://10.0.2.2:4000/api/users',
  'http://192.168.100.43:4000/api/users'
];

async function testUrl(url) {
  return new Promise((resolve) => {
    const isHttps = url.startsWith('https');
    const client = isHttps ? https : http;
    
    const req = client.get(url, { timeout: 5000 }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({
          url,
          status: res.statusCode,
          success: res.statusCode === 200,
          dataLength: data.length
        });
      });
    });
    
    req.on('error', (err) => {
      resolve({
        url,
        success: false,
        error: err.message
      });
    });
    
    req.on('timeout', () => {
      req.destroy();
      resolve({
        url,
        success: false,
        error: 'Timeout'
      });
    });
  });
}

async function runTests() {
  console.log('Testing network connectivity...\n');
  
  for (const url of testUrls) {
    const result = await testUrl(url);
    console.log(`${result.success ? '✅' : '❌'} ${result.url}`);
    if (result.success) {
      console.log(`   Status: ${result.status}, Data length: ${result.dataLength} bytes`);
    } else {
      console.log(`   Error: ${result.error}`);
    }
    console.log('');
  }
}

runTests().catch(console.error);
