/**
 * IndexedDB-backed {@link SettingsRepository}. Stores {@link AppSettings} and the PIN hash
 * in the `meta` store. PIN security uses Web Crypto PBKDF2 (SHA-256) over a random salt.
 */
import type { IDBPDatabase } from 'idb';
import type { AppSettings } from '@/domain/models';
import { DEFAULT_SETTINGS } from '@/domain/models';
import type { SettingsRepository } from '@/domain/services';
import { getDb, type DocScannerDB } from './db';

const SETTINGS_KEY = 'settings';
const PIN_KEY = 'pinHash';
const PBKDF2_ITERATIONS = 100_000;
const SALT_BYTES = 16;
const HASH_BITS = 256;

/** Persisted PIN material: base64 salt + derived hash. */
interface PinHash {
  salt: string;
  hash: string;
}

/** Encode a byte buffer as base64. */
function toBase64(bytes: ArrayBuffer | Uint8Array): string {
  const view = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let binary = '';
  for (let i = 0; i < view.length; i++) binary += String.fromCharCode(view[i]);
  return btoa(binary);
}

/** Decode base64 back into a byte array. */
function fromBase64(b64: string): Uint8Array {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Derive PBKDF2 bits for `pin` against `salt`, returned as base64. */
async function derive(pin: string, salt: Uint8Array): Promise<string> {
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(pin),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations: PBKDF2_ITERATIONS, hash: 'SHA-256' },
    keyMaterial,
    HASH_BITS,
  );
  return toBase64(bits);
}

/** Length-aware, branch-stable string comparison to avoid trivial timing leaks. */
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return mismatch === 0;
}

export class SettingsRepositoryImpl implements SettingsRepository {
  constructor(private readonly db: IDBPDatabase<DocScannerDB>) {}

  /** Convenience factory that resolves the singleton db. */
  static async create(): Promise<SettingsRepositoryImpl> {
    return new SettingsRepositoryImpl(await getDb());
  }

  async get(): Promise<AppSettings> {
    const stored = (await this.db.get('meta', SETTINGS_KEY)) as
      | Partial<AppSettings>
      | undefined;
    return { ...DEFAULT_SETTINGS, ...(stored ?? {}) };
  }

  async update(patch: Partial<AppSettings>): Promise<AppSettings> {
    const next = { ...(await this.get()), ...patch };
    await this.db.put('meta', next, SETTINGS_KEY);
    return next;
  }

  async setPin(pin: string): Promise<void> {
    const salt = crypto.getRandomValues(new Uint8Array(SALT_BYTES));
    const hash = await derive(pin, salt);
    const value: PinHash = { salt: toBase64(salt), hash };
    await this.db.put('meta', value, PIN_KEY);
  }

  async verifyPin(pin: string): Promise<boolean> {
    const stored = (await this.db.get('meta', PIN_KEY)) as PinHash | undefined;
    if (!stored) return false;
    const candidate = await derive(pin, fromBase64(stored.salt));
    return safeEqual(candidate, stored.hash);
  }

  async hasPin(): Promise<boolean> {
    const stored = await this.db.get('meta', PIN_KEY);
    return stored != null;
  }
}
