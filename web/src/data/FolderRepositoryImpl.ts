/**
 * IndexedDB-backed {@link FolderRepository}. Owns folders, tags, and the document↔tag
 * relation. Folder `documentCount` is computed on read from the documents `by-folder` index.
 */
import type { IDBPDatabase } from 'idb';
import type { Folder, Tag } from '@/domain/models';
import type { FolderRepository } from '@/domain/services';
import { getDb, type DocScannerDB } from './db';

export class FolderRepositoryImpl implements FolderRepository {
  constructor(private readonly db: IDBPDatabase<DocScannerDB>) {}

  /** Convenience factory that resolves the singleton db. */
  static async create(): Promise<FolderRepositoryImpl> {
    return new FolderRepositoryImpl(await getDb());
  }

  // --- folders ------------------------------------------------------------

  async getAll(parentId?: string | null): Promise<Folder[]> {
    let folders: Folder[];
    if (parentId === undefined) {
      folders = await this.db.getAll('folders');
    } else if (parentId === null) {
      folders = (await this.db.getAll('folders')).filter((f) => f.parentId === null);
    } else {
      folders = await this.db.getAllFromIndex('folders', 'by-parent', parentId);
    }
    return Promise.all(
      folders.map(async (folder) => ({
        ...folder,
        documentCount: await this.db.countFromIndex('documents', 'by-folder', folder.id),
      })),
    );
  }

  async create(folder: Folder): Promise<void> {
    // Never persist the derived `documentCount`.
    const { documentCount: _documentCount, ...record } = folder;
    void _documentCount;
    await this.db.put('folders', record);
  }

  async rename(id: string, name: string): Promise<void> {
    const tx = this.db.transaction('folders', 'readwrite');
    const store = tx.objectStore('folders');
    const folder = await store.get(id);
    if (folder) await store.put({ ...folder, name });
    await tx.done;
  }

  async delete(id: string): Promise<void> {
    await this.db.delete('folders', id);
  }

  // --- tags ---------------------------------------------------------------

  async getTags(): Promise<Tag[]> {
    return this.db.getAll('tags');
  }

  async createTag(tag: Tag): Promise<void> {
    await this.db.put('tags', tag);
  }

  /** Delete a tag and clear all of its document links. */
  async deleteTag(id: string): Promise<void> {
    const tx = this.db.transaction(['tags', 'documentTags'], 'readwrite');
    await tx.objectStore('tags').delete(id);
    const joinStore = tx.objectStore('documentTags');
    let cursor = await joinStore.index('by-tag').openCursor(id);
    while (cursor) {
      await cursor.delete();
      cursor = await cursor.continue();
    }
    await tx.done;
  }

  /** Replace the full set of tags attached to a document. */
  async setDocumentTags(documentId: string, tagIds: string[]): Promise<void> {
    const tx = this.db.transaction('documentTags', 'readwrite');
    const store = tx.objectStore('documentTags');
    let cursor = await store.index('by-document').openCursor(documentId);
    while (cursor) {
      await cursor.delete();
      cursor = await cursor.continue();
    }
    await Promise.all(tagIds.map((tagId) => store.put({ documentId, tagId })));
    await tx.done;
  }
}
