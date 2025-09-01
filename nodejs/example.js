#!/usr/bin/env node
/**
 * Example usage of the easykey Node.js package.
 *
 * This script demonstrates how to use the easykey package to interact
 * with the macOS keychain through the easykey CLI.
 *
 * Note: The Node.js package is read-only. To store or remove secrets,
 * use the easykey CLI directly:
 *   easykey set SECRET_NAME "secret_value"
 *   easykey remove SECRET_NAME
 */

const { spawn } = require('child_process');
const easykey = require('./index.js');

/**
 * Helper to run easykey CLI commands
 * @param {string[]} args - Command arguments
 * @returns {Promise<string>} Command output
 */
function runCliCommand(args) {
    return new Promise((resolve, reject) => {
        const child = spawn('easykey', args, {
            stdio: ['inherit', 'pipe', 'pipe'],
            encoding: 'utf8'
        });

        let stdout = '';
        let stderr = '';

        child.stdout.on('data', (data) => {
            stdout += data;
        });

        child.stderr.on('data', (data) => {
            stderr += data;
        });

        child.on('close', (code) => {
            if (code === 0) {
                resolve(stdout.trim());
            } else {
                reject(new easykey.EasyKeyError(`CLI command failed: ${stderr.trim()}`));
            }
        });

        child.on('error', (error) => {
            if (error.code === 'ENOENT') {
                reject(new easykey.EasyKeyError('easykey CLI not found. Please install the easykey CLI first.'));
            } else {
                reject(new easykey.EasyKeyError(`CLI command failed: ${error.message}`));
            }
        });
    });
}

async function main() {
    console.log('EasyKey Node.js Package Example');
    console.log('='.repeat(40));
    
    // Example secret name
    const secretName = 'example_secret';
    
    try {
        // Check vault status
        console.log('\n1. Checking vault status...');
        const status = easykey.status();
        console.log(`   Total secrets: ${status.secrets}`);
        console.log(`   Last access: ${status.last_access || 'Never'}`);
        
        // List existing secrets
        console.log('\n2. Listing existing secrets...');
        const secrets = easykey.list();
        if (secrets.length > 0) {
            for (const secret of secrets) {
                console.log(`   - ${secret.name}`);
            }
        } else {
            console.log('   No secrets found');
        }
        
        // Store a secret using CLI (Node.js package is read-only)
        console.log(`\n3. Storing secret '${secretName}' using CLI...`);
        console.log('   Note: Using CLI directly since Node.js package is read-only');
        try {
            await runCliCommand([
                'set', 
                secretName, 
                'my-example-secret-value', 
                '--reason', 
                'Example script demonstration'
            ]);
            console.log('   Secret stored successfully!');
        } catch (error) {
            console.log(`   Failed to store secret: ${error.message}`);
            console.log('   Continuing with example assuming secret exists...');
        }
        
        // Retrieve the secret using Node.js package
        console.log(`\n4. Retrieving secret '${secretName}' using Node.js...`);
        try {
            const retrievedSecret = easykey.secret(
                secretName,
                'Example script retrieval'
            );
            console.log(`   Retrieved: ${retrievedSecret}`);
        } catch (error) {
            console.log(`   Could not retrieve secret: ${error.message}`);
            console.log(`   Make sure the secret exists by running: easykey set ${secretName} 'test-value'`);
        }
        
        // List secrets again with timestamps
        console.log('\n5. Listing secrets with timestamps...');
        const secretsWithTimestamps = easykey.list(true);
        for (const secret of secretsWithTimestamps) {
            const created = secret.createdAt || 'Unknown';
            console.log(`   - ${secret.name} (created: ${created})`);
        }
        
        // Clean up - remove the example secret using CLI
        console.log(`\n6. Cleaning up - removing '${secretName}' using CLI...`);
        try {
            await runCliCommand([
                'remove', 
                secretName, 
                '--reason', 
                'Example script cleanup'
            ]);
            console.log('   Secret removed successfully!');
        } catch (error) {
            console.log(`   Note: Could not remove secret (might not exist): ${error.message}`);
        }
        
        console.log('\n✅ Example completed successfully!');
        console.log('\n💡 Tips:');
        console.log('   - Use the easykey CLI for storing/removing secrets');
        console.log('   - Use the Node.js package for reading secrets in your applications');
        console.log('   - All operations require biometric authentication');
        
    } catch (error) {
        if (error instanceof easykey.EasyKeyError) {
            console.error(`\n❌ EasyKey error: ${error.message}`);
            return 1;
        } else {
            console.error(`\n❌ Unexpected error: ${error.message}`);
            return 1;
        }
    }
    
    return 0;
}

// Handle SIGINT (Ctrl+C) gracefully
process.on('SIGINT', () => {
    console.log('\n\n🛑 Interrupted by user');
    process.exit(1);
});

// Run the example if this script is executed directly
if (require.main === module) {
    main().then(process.exit).catch((error) => {
        console.error(`\n❌ Unexpected error: ${error.message}`);
        process.exit(1);
    });
}
