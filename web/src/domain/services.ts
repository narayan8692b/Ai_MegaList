/**
 * Service + repository contracts. Implementations live under `src/data` and `src/services`.
 * UI code depends only on these interfaces (Repository pattern), mirroring the KMM design.
 */
import type {
  AppSettings,
  CapturedImage,
  Document,
  DocumentCorners,
  Folder,
  OcrResult,
  PdfQuality,
  ScanFilter,
  Tag,
} from './models';

export interface DocumentRepository {
  getAll(folderId?: string | null): Promise<Document[]>;
  getById(id: string): Promise<Document | null>;
  search(query: string): Promise<Document[]>;
  upsert(doc: Document): Promise<void>;
  delete(id: string): Promise<void>;
  setFavorite(id: string, favorite: boolean): Promise<void>;
  setLocked(id: string, locked: boolean): Promise<void>;
  moveToFolder(id: string, folderId: string | null): Promise<void>;
  /** Resolve a stored blob (page image / export) by id, e.g. for rendering or export. */
  getBlob(blobId: string): Promise<Blob | null>;
  putBlob(blobId: string, blob: Blob): Promise<void>;
}

export interface FolderRepository {
  getAll(parentId?: string | null): Promise<Folder[]>;
  create(folder: Folder): Promise<void>;
  rename(id: string, name: string): Promise<void>;
  delete(id: string): Promise<void>;
  getTags(): Promise<Tag[]>;
  createTag(tag: Tag): Promise<void>;
  deleteTag(id: string): Promise<void>;
  setDocumentTags(documentId: string, tagIds: string[]): Promise<void>;
}

export interface SettingsRepository {
  get(): Promise<AppSettings>;
  update(patch: Partial<AppSettings>): Promise<AppSettings>;
  setPin(pin: string): Promise<void>;
  verifyPin(pin: string): Promise<boolean>;
  hasPin(): Promise<boolean>;
}

/** Native camera + gallery integration via getUserMedia / file input. */
export interface CameraService {
  isCameraAvailable(): Promise<boolean>;
  /** Start a live camera stream into the given <video> element. Returns a stop function. */
  startStream(video: HTMLVideoElement, facingMode?: 'environment' | 'user'): Promise<() => void>;
  /** Grab a still frame from a running stream. */
  capture(video: HTMLVideoElement): Promise<CapturedImage>;
  /** Import image(s) from the file picker / gallery. */
  pickFromGallery(allowMultiple?: boolean): Promise<CapturedImage[]>;
}

/** Edge detection, perspective correction and filters. Heavy work runs in a Web Worker. */
export interface ImageProcessor {
  detectEdges(blob: Blob): Promise<DocumentCorners>;
  perspectiveCorrect(blob: Blob, corners: DocumentCorners): Promise<Blob>;
  applyFilter(blob: Blob, filter: ScanFilter): Promise<Blob>;
  createThumbnail(blob: Blob, maxSize?: number): Promise<Blob>;
  dimensions(blob: Blob): Promise<{ width: number; height: number }>;
}

/** OCR via Tesseract.js. */
export interface OcrEngine {
  recognize(blob: Blob): Promise<OcrResult>;
}

/** PDF generation + JPG export via jsPDF / canvas. */
export interface PdfService {
  generatePdf(blobs: Blob[], quality?: PdfQuality, password?: string): Promise<Blob>;
  exportJpg(blob: Blob, quality?: PdfQuality): Promise<Blob>;
}

/** File download + Web Share API. */
export interface ShareService {
  download(blob: Blob, filename: string): void;
  canShare(): boolean;
  share(blob: Blob, filename: string, mimeType: string): Promise<void>;
}

export interface IdGenerator {
  newId(): string;
}
