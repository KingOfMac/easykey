/**
 * EasyKey Node.js Package Type Definitions
 * 
 * TypeScript definitions for the easykey CLI wrapper
 */

/**
 * Custom error class for EasyKey operations
 */
export class EasyKeyError extends Error {
    constructor(message: string);
}

/**
 * Secret information object returned by list()
 */
export interface SecretInfo {
    /** The name/identifier of the secret */
    name: string;
    /** Creation timestamp (if includeTimestamps=true) */
    createdAt?: string;
    /** Additional metadata fields */
    [key: string]: any;
}

/**
 * Vault status information object returned by status()
 */
export interface VaultStatus {
    /** Number of secrets in the vault */
    secrets: number;
    /** Timestamp of last access, or null if never accessed */
    last_access: string | null;
    /** Additional status fields */
    [key: string]: any;
}

/**
 * Retrieve a secret from the easykey vault
 * @param name The name of the secret to retrieve
 * @param reason Optional reason for accessing the secret (for audit logging)
 * @returns The secret value as a string
 * @throws {EasyKeyError} If the secret cannot be retrieved
 */
export function secret(name: string, reason?: string): string;

/**
 * Alias for secret() function - retrieve a secret from the easykey vault
 * @param name The name of the secret to retrieve
 * @param reason Optional reason for accessing the secret (for audit logging)
 * @returns The secret value as a string
 * @throws {EasyKeyError} If the secret cannot be retrieved
 */
export function getSecret(name: string, reason?: string): string;

/**
 * List all secrets in the easykey vault
 * @param includeTimestamps Whether to include creation timestamps
 * @returns A list of objects containing secret information
 * @throws {EasyKeyError} If the secrets cannot be listed
 */
export function list(includeTimestamps?: boolean): SecretInfo[];

/**
 * Get the status of the easykey vault
 * @returns An object containing vault status information
 * @throws {EasyKeyError} If the status cannot be retrieved
 */
export function status(): VaultStatus;
