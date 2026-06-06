/**
 * Mappers between the {@link Document} aggregate and its persisted parts
 * (a {@link StoredDocument} record + a list of {@link Page}s + a list of tag ids).
 */
import type { Document, Page, Tag } from '@/domain/models';
import type { StoredDocument } from './db';

/** Split a full {@link Document} into the record stored in the `documents` store. */
export function toStoredDocument(doc: Document): StoredDocument {
  return {
    id: doc.id,
    title: doc.title,
    folderId: doc.folderId,
    ocrText: doc.ocrText,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
    isFavorite: doc.isFavorite,
    isLocked: doc.isLocked,
    syncStatus: doc.syncStatus,
  };
}

/** Extract the tag ids referenced by a document (for the `documentTags` join store). */
export function toTagIds(doc: Document): string[] {
  return doc.tags.map((t) => t.id);
}

/**
 * Assemble a full {@link Document} aggregate from its stored record plus the pages and
 * tags resolved from their respective stores. Callers must pass pages already sorted by
 * `orderIndex`. Enum-valued fields are string enums and are kept as-is.
 */
export function fromStoredDocument(
  record: StoredDocument,
  pages: Page[],
  tags: Tag[],
): Document {
  return {
    id: record.id,
    title: record.title,
    pages,
    folderId: record.folderId,
    tags,
    ocrText: record.ocrText,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isFavorite: record.isFavorite,
    isLocked: record.isLocked,
    syncStatus: record.syncStatus,
  };
}
