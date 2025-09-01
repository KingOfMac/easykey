/**
 * EasyKey Node.js Package
 * 
 * A simple Node.js wrapper for the easykey CLI that provides secure keychain access.
 */

const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

/**
 * Custom error class for EasyKey operations
 */
class EasyKeyError extends Error {
    constructor(message) {
        super(message);
        this.name = 'EasyKeyError';
    }
}

/**
 * Find the easykey binary in common locations
 * @returns {string} Path to the easykey binary
 * @throws {EasyKeyError} If binary is not found
 */
function _findEasyKeyBinary() {
    // Check common installation locations
    const commonPaths = [
        '/usr/local/bin/easykey',
        '/opt/homebrew/bin/easykey',
        path.join(os.homedir(), 'bin/easykey'),
        // Check relative to this package (if installed alongside)
        path.join(__dirname, '../../bin/easykey'),
    ];
    
    // Check if it's in PATH
    const pathEnv = process.env.PATH || '';
    const pathDirs = pathEnv.split(path.delimiter);
    
    for (const dir of pathDirs) {
        const binaryPath = path.join(dir, 'easykey');
        if (fs.existsSync(binaryPath)) {
            try {
                fs.accessSync(binaryPath, fs.constants.X_OK);
                return binaryPath;
            } catch (e) {
                // Not executable, continue searching
            }
        }
    }
    
    // Check common paths
    for (const binaryPath of commonPaths) {
        if (fs.existsSync(binaryPath)) {
            try {
                fs.accessSync(binaryPath, fs.constants.X_OK);
                return binaryPath;
            } catch (e) {
                // Not executable, continue searching
            }
        }
    }
    
    throw new EasyKeyError(
        'easykey binary not found. Please ensure easykey is installed and available in PATH, ' +
        'or install it to one of the standard locations: /usr/local/bin, /opt/homebrew/bin, or ~/bin'
    );
}

/**
 * Run easykey command and return stdout
 * @param {string[]} args - Command arguments
 * @returns {string} Command output
 * @throws {EasyKeyError} If command fails
 */
function _runEasyKeyCommand(args) {
    try {
        const binaryPath = _findEasyKeyBinary();
        const result = spawnSync(binaryPath, args, {
            encoding: 'utf8',
            stdio: ['inherit', 'pipe', 'pipe']
        });
        
        if (result.error) {
            throw new EasyKeyError(`easykey binary not found: ${result.error.message}`);
        }
        
        if (result.status !== 0) {
            const errorMsg = result.stderr ? result.stderr.trim() : `Command failed with status ${result.status}`;
            throw new EasyKeyError(`easykey command failed: ${errorMsg}`);
        }
        
        return result.stdout.trim();
    } catch (error) {
        if (error instanceof EasyKeyError) {
            throw error;
        }
        throw new EasyKeyError(`easykey command failed: ${error.message}`);
    }
}

/**
 * Retrieve a secret from the easykey vault
 * @param {string} name - The name of the secret to retrieve
 * @param {string} [reason] - Optional reason for accessing the secret (for audit logging)
 * @returns {string} The secret value as a string
 * @throws {EasyKeyError} If the secret cannot be retrieved
 */
function secret(name, reason = null) {
    if (typeof name !== 'string' || name.trim() === '') {
        throw new EasyKeyError('Secret name must be a non-empty string');
    }
    
    const args = ['get', name, '--quiet'];
    if (reason) {
        args.push('--reason', reason);
    }
    
    return _runEasyKeyCommand(args);
}

/**
 * List all secrets in the easykey vault
 * @param {boolean} [includeTimestamps=false] - Whether to include creation timestamps
 * @returns {Object[]} A list of objects containing secret information
 * @throws {EasyKeyError} If the secrets cannot be listed
 */
function list(includeTimestamps = false) {
    const args = ['list', '--json'];
    if (includeTimestamps) {
        args.push('--verbose');
    }
    
    const output = _runEasyKeyCommand(args);
    if (!output) {
        return [];
    }
    
    try {
        return JSON.parse(output);
    } catch (error) {
        throw new EasyKeyError(`Failed to parse easykey output: ${error.message}`);
    }
}

/**
 * Get the status of the easykey vault
 * @returns {Object} A dictionary containing vault status information
 * @throws {EasyKeyError} If the status cannot be retrieved
 */
function status() {
    const output = _runEasyKeyCommand(['status']);
    
    // Parse the output format:
    // secrets: 5
    // last_access: 2023-08-27T15:30:45.123Z
    const result = {};
    const lines = output.split('\n');
    
    for (const line of lines) {
        if (line.includes(':')) {
            const [key, ...valueParts] = line.split(':');
            const trimmedKey = key.trim();
            const value = valueParts.join(':').trim();
            
            if (trimmedKey === 'secrets') {
                result.secrets = parseInt(value, 10);
            } else if (trimmedKey === 'last_access') {
                result.last_access = value === '-' ? null : value;
            } else {
                result[trimmedKey] = value;
            }
        }
    }
    
    return result;
}

// Alias for backward compatibility and convenience
const getSecret = secret;

module.exports = {
    secret,
    getSecret,
    list,
    status,
    EasyKeyError
};
