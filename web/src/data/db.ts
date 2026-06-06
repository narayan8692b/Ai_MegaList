/**
 * IndexedDB schema + connection for DocScanner, using the `idb` library.
 *
 * Documents are stored WITHOUT their `pages`/`tags` arrays; pages live in their own
 * store (indexed by `documentId`), page image data lives in the `blobs` store, and the
 * document↔tag relation is a join store (`documentTags`). The repositories assemble full
 * {@link Document} aggregates on read.
 */
import { openDB, type DBSchema, type IDBPDatabase } from 'idb';
import type { Folder, Page, SyncStatus, Tag } from '@/domain/models';

/** Document fields persisted in the `documents` store (no `pages`/`tags` arrays). */
export interface StoredDocument {
  id: string;
  title: string;
  folderId: string | null;
  ocrText: string;
  createdAt: number;
  updatedAt: number;
  isFavorite: boolean;
  isLocked: boolean;
  syncStatus: SyncStatus;
}

/** A stored blob entry keyed by its blob id. */
export interface StoredBlob {
  id: string;
  blob: Blob;
}

/** Folder fields persisted (the computed `documentCount` is derived on read, not stored). */
export type StoredFolder = Omit<Folder, 'documentCount'>;

/** A row in the document↔tag many-to-many join store. */
export interface DocumentTag {
  documentId: string;
  tagId: string;
}

/** Strongly-typed schema describing every object store + index. */
export interface DocScannerDB extends DBSchema {
  documents: {
    key: string;
    value: StoredDocument;
    indexes: { 'by-folder': string; 'by-updated': number };
  };
  pages: {
    key: string;
    value: Page;
    indexes: { 'by-document': string };
  };
  blobs: {
    key: string;
    value: StoredBlob;
  };
  folders: {
    key: string;
    value: StoredFolder;
    indexes: { 'by-parent': string };
  };
  tags: {
    key: string;
    value: Tag;
  };
  documentTags: {
    key: [string, string];
    value: DocumentTag;
    indexes: { 'by-document': string; 'by-tag': string };
  };
  meta: {
    key: string;
    value: unknown;
  };
}

const DB_NAME = 'docscanner';
const DB_VERSION = 1;

let dbPromise: Promise<IDBPDatabase<DocScannerDB>> | null = null;

/** Open (or reuse) the singleton IndexedDB connection. */
export function getDb(): Promise<IDBPDatabase<DocScannerDB>> {
  if (!dbPromise) {
    dbPromise = openDB<DocScannerDB>(DB_NAME, DB_VERSION, {
      upgrade(db) {
        const documents = db.createObjectStore('documents', { keyPath: 'id' });
        documents.createIndex('by-folder', 'folderId');
        documents.createIndex('by-updated', 'updatedAt');

        const pages = db.createObjectStore('pages', { keyPath: 'id' });
        pages.createIndex('by-document', 'documentId');

        db.createObjectStore('blobs', { keyPath: 'id' });

        const folders = db.createObjectStore('folders', { keyPath: 'id' });
        folders.createIndex('by-parent', 'parentId');

        db.createObjectStore('tags', { keyPath: 'id' });

        const documentTags = db.createObjectStore('documentTags', {
          keyPath: ['documentId', 'tagId'],
        });
        documentTags.createIndex('by-document', 'documentId');
        documentTags.createIndex('by-tag', 'tagId');

        db.createObjectStore('meta');
      },
    });
  }
  return dbPromise;
}

/**
 * Best-effort request for persistent storage so the browser is less likely to evict
 * the database under storage pressure. Safe to call repeatedly; never throws.
 */
export async function requestPersistentStorage(): Promise<boolean> {
  try {
    if (navigator.storage?.persist) {
      return await navigator.storage.persist();
    }
  } catch {
    /* ignore — persistence is an optimisation, not a requirement */
  }
  return false;
}
