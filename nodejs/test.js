#!/usr/bin/env node
/**
 * Simple test runner for the easykey npm package
 */

const easykey = require('./index.js');

function test(name, fn) {
    try {
        fn();
        console.log(`✅ ${name}`);
        return true;
    } catch (error) {
        console.error(`❌ ${name}: ${error.message}`);
        return false;
    }
}

function assertEquals(actual, expected, message) {
    if (actual !== expected) {
        throw new Error(`${message}: expected ${expected}, got ${actual}`);
    }
}

function assertTrue(value, message) {
    if (!value) {
        throw new Error(message);
    }
}

console.log('Running easykey npm package tests...\n');

let passed = 0;
let total = 0;

// Test 1: Module exports
total++;
passed += test('Module exports all required functions', () => {
    assertTrue(typeof easykey.secret === 'function', 'secret function should be exported');
    assertTrue(typeof easykey.getSecret === 'function', 'getSecret function should be exported');
    assertTrue(typeof easykey.list === 'function', 'list function should be exported');
    assertTrue(typeof easykey.status === 'function', 'status function should be exported');
    assertTrue(typeof easykey.EasyKeyError === 'function', 'EasyKeyError should be exported');
});

// Test 2: EasyKeyError class
total++;
passed += test('EasyKeyError is a proper Error subclass', () => {
    const error = new easykey.EasyKeyError('test message');
    assertTrue(error instanceof Error, 'EasyKeyError should extend Error');
    assertTrue(error instanceof easykey.EasyKeyError, 'EasyKeyError should be instance of itself');
    assertEquals(error.name, 'EasyKeyError', 'Error name should be EasyKeyError');
    assertEquals(error.message, 'test message', 'Error message should be preserved');
});

// Test 3: Function argument validation
total++;
passed += test('secret() validates arguments', () => {
    try {
        easykey.secret('');
        throw new Error('Should have thrown for empty string');
    } catch (error) {
        assertTrue(error instanceof easykey.EasyKeyError, 'Should throw EasyKeyError for empty string');
    }
    
    try {
        easykey.secret(null);
        throw new Error('Should have thrown for null');
    } catch (error) {
        assertTrue(error instanceof easykey.EasyKeyError, 'Should throw EasyKeyError for null');
    }
});

// Test 4: getSecret alias
total++;
passed += test('getSecret is an alias for secret', () => {
    assertEquals(easykey.getSecret, easykey.secret, 'getSecret should be the same function as secret');
});

// Test 5: list() function default parameter
total++;
passed += test('list() accepts boolean parameter', () => {
    // This test just checks that the function can be called with different parameters
    // without throwing synchronous errors (actual CLI calls will fail in test environment)
    assertTrue(typeof easykey.list() !== 'undefined', 'list() should be callable without parameters');
    assertTrue(typeof easykey.list(false) !== 'undefined', 'list(false) should be callable');
    assertTrue(typeof easykey.list(true) !== 'undefined', 'list(true) should be callable');
});

console.log(`\nTest Results: ${passed}/${total} passed`);

if (passed === total) {
    console.log('🎉 All tests passed!');
    process.exit(0);
} else {
    console.log('💥 Some tests failed!');
    process.exit(1);
}
