/**
 * IndexedDB-backed {@link DocumentRepository}. Persists documents as flat records and
 * assembles full {@link Document} aggregates (pages + tags) on read.
 */
import type { IDBPDatabase } from 'idb';
import type { Document, Page, Tag } from '@/domain/models';
import type { DocumentRepository } from '@/domain/services';
import { getDb, type DocScannerDB, type StoredDocument } from './db';
import { fromStoredDocument, toStoredDocument, toTagIds } from './mappers';

export class DocumentRepositoryImpl implements DocumentRepository {
  constructor(private readonly db: IDBPDatabase<DocScannerDB>) {}

  /** Convenience factory that resolves the singleton db. */
  static async create(): Promise<DocumentRepositoryImpl> {
    return new DocumentRepositoryImpl(await getDb());
  }

  // --- assembly helpers ---------------------------------------------------

  /** Load pages for a document, sorted by `orderIndex` ascending. */
  private async loadPages(documentId: string): Promise<Page[]> {
    const pages = await this.db.getAllFromIndex('pages', 'by-document', documentId);
    return pages.sort((a, b) => a.orderIndex - b.orderIndex);
  }

  /** Resolve the tags attached to a document via the join store. */
  private async loadTags(documentId: string): Promise<Tag[]> {
    const joins = await this.db.getAllFromIndex('documentTags', 'by-document', documentId);
    const tags = await Promise.all(joins.map((j) => this.db.get('tags', j.tagId)));
    return tags.filter((t): t is Tag => t != null);
  }

  /** Build the full aggregate for a stored record. */
  private async assemble(record: StoredDocument): Promise<Document> {
    const [pages, tags] = await Promise.all([
      this.loadPages(record.id),
      this.loadTags(record.id),
    ]);
    return fromStoredDocument(record, pages, tags);
  }

  // --- queries ------------------------------------------------------------

  async getAll(folderId?: string | null): Promise<Document[]> {
    let records: StoredDocument[];
    if (folderId === undefined) {
      records = await this.db.getAll('documents');
    } else if (folderId === null) {
      // Top-level documents (no folder) — the index can't key on null, so filter.
      records = (await this.db.getAll('documents')).filter((r) => r.folderId === null);
    } else {
      records = await this.db.getAllFromIndex('documents', 'by-folder', folderId);
    }
    const docs = await Promise.all(records.map((r) => this.assemble(r)));
    return docs.sort((a, b) => b.updatedAt - a.updatedAt);
  }

  async getById(id: string): Promise<Document | null> {
    const record = await this.db.get('documents', id);
    return record ? this.assemble(record) : null;
  }

  async search(query: string): Promise<Document[]> {
    const q = query.trim().toLowerCase();
    const records = await this.db.getAll('documents');
    const all = await Promise.all(records.map((r) => this.assemble(r)));
    const sorted = all.sort((a, b) => b.updatedAt - a.updatedAt);
    if (q === '') return sorted;
    return sorted.filter((doc) => {
      if (doc.title.toLowerCase().includes(q)) return true;
      if (doc.ocrText.toLowerCase().includes(q)) return true;
      return doc.tags.some((t) => t.name.toLowerCase().includes(q));
    });
  }

  // --- writes -------------------------------------------------------------

  /**
   * Insert or replace a document, its pages and its tag links atomically. Blob data must
   * already be written via {@link putBlob} before calling this.
   */
  async upsert(doc: Document): Promise<void> {
    const tx = this.db.transaction(['documents', 'pages', 'documentTags'], 'readwrite');
    const documents = tx.objectStore('documents');
    const pages = tx.objectStore('pages');
    const documentTags = tx.objectStore('documentTags');

    await documents.put(toStoredDocument(doc));

    // Replace pages: delete stale rows then write the current set.
    const pageIndex = pages.index('by-document');
    let cursor = await pageIndex.openCursor(doc.id);
    while (cursor) {
      await cursor.delete();
      cursor = await cursor.continue();
    }
    await Promise.all(doc.pages.map((p) => pages.put(p)));

    // Refresh tag links: delete stale rows then write the current set.
    const tagIndex = documentTags.index('by-document');
    let tagCursor = await tagIndex.openCursor(doc.id);
    while (tagCursor) {
      await tagCursor.delete();
      tagCursor = await tagCursor.continue();
    }
    await Promise.all(
      toTagIds(doc).map((tagId) => documentTags.put({ documentId: doc.id, tagId })),
    );

    await tx.done;
  }

  async delete(id: string): Promise<void> {
    // Collect page blob ids first so we can purge the blob store too.
    const pages = await this.db.getAllFromIndex('pages', 'by-document', id);
    const blobIds = new Set<string>();
    for (const p of pages) {
      if (p.originalBlobId) blobIds.add(p.originalBlobId);
      if (p.processedBlobId) blobIds.add(p.processedBlobId);
    }

    const tx = this.db.transaction(
      ['documents', 'pages', 'documentTags', 'blobs'],
      'readwrite',
    );
    await tx.objectStore('documents').delete(id);

    const pageStore = tx.objectStore('pages');
    let pageCursor = await pageStore.index('by-document').openCursor(id);
    while (pageCursor) {
      await pageCursor.delete();
      pageCursor = await pageCursor.continue();
    }

    const joinStore = tx.objectStore('documentTags');
    let joinCursor = await joinStore.index('by-document').openCursor(id);
    while (joinCursor) {
      await joinCursor.delete();
      joinCursor = await joinCursor.continue();
    }

    const blobStore = tx.objectStore('blobs');
    await Promise.all([...blobIds].map((b) => blobStore.delete(b)));

    await tx.done;
  }

  // --- field mutations ----------------------------------------------------

  private async patchRecord(
    id: string,
    patch: Partial<StoredDocument>,
  ): Promise<void> {
    const tx = this.db.transaction('documents', 'readwrite');
    const store = tx.objectStore('documents');
    const record = await store.get(id);
    if (record) {
      await store.put({ ...record, ...patch, updatedAt: Date.now() });
    }
    await tx.done;
  }

  setFavorite(id: string, favorite: boolean): Promise<void> {
    return this.patchRecord(id, { isFavorite: favorite });
  }

  setLocked(id: string, locked: boolean): Promise<void> {
    return this.patchRecord(id, { isLocked: locked });
  }

  moveToFolder(id: string, folderId: string | null): Promise<void> {
    return this.patchRecord(id, { folderId });
  }

  // --- blobs --------------------------------------------------------------

  async getBlob(blobId: string): Promise<Blob | null> {
    const entry = await this.db.get('blobs', blobId);
    return entry?.blob ?? null;
  }

  async putBlob(blobId: string, blob: Blob): Promise<void> {
    await this.db.put('blobs', { id: blobId, blob });
  }
}
