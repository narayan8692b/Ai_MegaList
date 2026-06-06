/**
 * Composition root for the data layer. Opens IndexedDB, requests persistent storage, and
 * wires up the concrete repository implementations behind their domain interfaces.
 */
import type {
  DocumentRepository,
  FolderRepository,
  IdGenerator,
  SettingsRepository,
} from '@/domain/services';
import { getDb, requestPersistentStorage } from './db';
import { DocumentRepositoryImpl } from './DocumentRepositoryImpl';
import { FolderRepositoryImpl } from './FolderRepositoryImpl';
import { SettingsRepositoryImpl } from './SettingsRepositoryImpl';
import { IdGeneratorImpl } from './IdGeneratorImpl';

export interface DataLayer {
  documents: DocumentRepository;
  folders: FolderRepository;
  settings: SettingsRepository;
  ids: IdGenerator;
}

/** Open the database and build the fully-wired data layer. */
export async function createDataLayer(): Promise<DataLayer> {
  const db = await getDb();
  await requestPersistentStorage();
  return {
    documents: new DocumentRepositoryImpl(db),
    folders: new FolderRepositoryImpl(db),
    settings: new SettingsRepositoryImpl(db),
    ids: new IdGeneratorImpl(),
  };
}
