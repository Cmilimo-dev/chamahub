#!/usr/bin/env node

/**
 * Security Audit Script for ChamaHub
 * Checks for common security issues before production deployment
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.join(__dirname, '..');

console.log('🔒 Running Security Audit for ChamaHub\n');

let issues = [];
let warnings = [];

// 1. Check environment variables
function checkEnvironmentVariables() {
  console.log('1. Checking environment variables...');
  
  const envFiles = ['.env.local', '.env.production'];
  const requiredVars = [
    'VITE_SUPABASE_URL',
    'VITE_SUPABASE_ANON_KEY',
    'VITE_MPESA_CONSUMER_KEY',
    'VITE_MPESA_CONSUMER_SECRET',
    'VITE_FIREBASE_API_KEY'
  ];

  envFiles.forEach(envFile => {
    const envPath = path.join(rootDir, envFile);
    if (fs.existsSync(envPath)) {
      const envContent = fs.readFileSync(envPath, 'utf8');
      
      // Check for hardcoded secrets (not in environment)
      if (envContent.includes('sk_live_') || envContent.includes('pk_live_')) {
        issues.push(`❌ Live API keys found in ${envFile}`);
      }
      
      // Check for missing required variables
      requiredVars.forEach(varName => {
        if (!envContent.includes(varName)) {
          warnings.push(`⚠️  Missing ${varName} in ${envFile}`);
        }
      });
    } else {
      warnings.push(`⚠️  Environment file ${envFile} not found`);
    }
  });
  
  console.log('   ✓ Environment variables checked\n');
}

// 2. Check for exposed secrets in code
function checkForExposedSecrets() {
  console.log('2. Scanning for exposed secrets in code...');
  
  const sensitivePatterns = [
    /sk_live_[a-zA-Z0-9]{99}/g, // Stripe live secret keys
    /pk_live_[a-zA-Z0-9]{99}/g, // Stripe live publishable keys
    /AIza[0-9A-Za-z\\-_]{35}/g, // Google API keys
    /ya29\\.[0-9A-Za-z\\-_]+/g, // Google OAuth tokens
    /(?:password|passwd|pwd)\\s*[=:]\\s*['\"][^'\"]+['\"]/gi,
    /(?:secret|token|key)\\s*[=:]\\s*['\"][^'\"]+['\"]/gi
  ];
  
  function scanDirectory(dir) {
    const files = fs.readdirSync(dir);
    
    files.forEach(file => {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isDirectory() && !file.startsWith('.') && file !== 'node_modules') {
        scanDirectory(filePath);
      } else if (file.endsWith('.ts') || file.endsWith('.tsx') || file.endsWith('.js') || file.endsWith('.jsx')) {
        const content = fs.readFileSync(filePath, 'utf8');
        
        sensitivePatterns.forEach(pattern => {
          const matches = content.match(pattern);
          if (matches) {
            issues.push(`❌ Potential secret exposed in ${filePath}: ${matches[0].substring(0, 20)}...`);
          }
        });
      }
    });
  }
  
  scanDirectory(path.join(rootDir, 'src'));
  console.log('   ✓ Code scanned for exposed secrets\n');
}

// 3. Check HTTPS enforcement
function checkHTTPSEnforcement() {
  console.log('3. Checking HTTPS enforcement...');
  
  const viteConfigPath = path.join(rootDir, 'vite.config.ts');
  if (fs.existsSync(viteConfigPath)) {
    const viteConfig = fs.readFileSync(viteConfigPath, 'utf8');
    
    if (!viteConfig.includes('https:') && !viteConfig.includes('secure: true')) {
      warnings.push('⚠️  HTTPS not explicitly configured in Vite config');
    }
  }
  
  console.log('   ✓ HTTPS enforcement checked\n');
}

// 4. Check input validation
function checkInputValidation() {
  console.log('4. Checking input validation...');
  
  const formFiles = [];
  
  function findFormFiles(dir) {
    const files = fs.readdirSync(dir);
    
    files.forEach(file => {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isDirectory() && !file.startsWith('.') && file !== 'node_modules') {
        findFormFiles(filePath);
      } else if ((file.endsWith('.ts') || file.endsWith('.tsx')) && 
                 (file.toLowerCase().includes('form') || file.toLowerCase().includes('input'))) {
        const content = fs.readFileSync(filePath, 'utf8');
        
        // Check for Zod validation
        if (!content.includes('z.') && !content.includes('zod') && content.includes('input')) {
          warnings.push(`⚠️  No input validation found in ${filePath}`);
        }
        
        // Check for SQL injection prevention
        if (content.includes('${') && content.includes('query')) {
          warnings.push(`⚠️  Potential SQL injection risk in ${filePath}`);
        }
      }
    });
  }
  
  findFormFiles(path.join(rootDir, 'src'));
  console.log('   ✓ Input validation checked\n');
}

// 5. Check dependencies for vulnerabilities
function checkDepencies() {
  console.log('5. Checking dependencies...');
  
  const packageJsonPath = path.join(rootDir, 'package.json');
  if (fs.existsSync(packageJsonPath)) {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    
    // Check for known vulnerable packages
    const vulnerablePackages = ['lodash', 'moment', 'request'];
    const dependencies = { ...packageJson.dependencies, ...packageJson.devDependencies };
    
    vulnerablePackages.forEach(pkg => {
      if (dependencies[pkg]) {
        warnings.push(`⚠️  Consider replacing ${pkg} with safer alternatives`);
      }
    });
  }
  
  console.log('   ✓ Dependencies checked\n');
}

// 6. Check file permissions and structure
function checkFileStructure() {
  console.log('6. Checking file structure and permissions...');
  
  // Check for sensitive files that shouldn't be in version control
  const sensitiveFiles = ['.env', '.env.local', '.env.production', 'private.key', '*.p12', '*.keystore'];
  
  sensitiveFiles.forEach(pattern => {
    const files = fs.readdirSync(rootDir).filter(file => file.match(pattern.replace('*', '.*')));
    files.forEach(file => {
      warnings.push(`⚠️  Sensitive file ${file} found in root directory`);
    });
  });
  
  console.log('   ✓ File structure checked\n');
}

// 7. Check build configuration
function checkBuildConfig() {
  console.log('7. Checking build configuration...');
  
  const buildFiles = ['vite.config.ts', 'android/app/build.gradle'];
  
  buildFiles.forEach(file => {
    const filePath = path.join(rootDir, file);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      
      if (file.includes('build.gradle')) {
        if (!content.includes('minifyEnabled true')) {
          warnings.push('⚠️  Code minification not enabled in Android build');
        }
        if (!content.includes('proguardFiles')) {
          warnings.push('⚠️  ProGuard not configured for Android build');
        }
      }
    } else {
      warnings.push(`⚠️  Build file ${file} not found`);
    }
  });
  
  console.log('   ✓ Build configuration checked\n');
}

// Run all checks
async function runAudit() {
  checkEnvironmentVariables();
  checkForExposedSecrets();
  checkHTTPSEnforcement();
  checkInputValidation();
  checkDepencies();
  checkFileStructure();
  checkBuildConfig();
  
  // Print results
  console.log('🔒 Security Audit Results\n');
  console.log('='.repeat(50));
  
  if (issues.length === 0) {
    console.log('✅ No critical security issues found!');
  } else {
    console.log(`❌ Found ${issues.length} critical security issue(s):`);
    issues.forEach(issue => console.log(issue));
  }
  
  if (warnings.length > 0) {
    console.log(`\n⚠️  Found ${warnings.length} warning(s):`);
    warnings.forEach(warning => console.log(warning));
  }
  
  console.log('\n' + '='.repeat(50));
  
  if (issues.length === 0) {
    console.log('✅ Security audit passed! Ready for production.');
    process.exit(0);
  } else {
    console.log('❌ Security audit failed. Please fix critical issues before deployment.');
    process.exit(1);
  }
}

runAudit().catch(console.error);
