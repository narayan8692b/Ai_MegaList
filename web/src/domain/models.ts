/**
 * Domain models for DocScanner PWA. Mirrors the Kotlin Multiplatform domain layer so the
 * web app shares the same mental model (Document → Pages, Folders, Tags, filters, corners).
 */

/** A normalized point. Coordinates are in the range [0, 1] relative to image size. */
export interface PointF {
  x: number;
  y: number;
}

/**
 * The four document corners, clockwise from top-left, normalized (0..1) so they survive
 * image resizes. Used by the corner-adjustment screen + perspective correction.
 */
export interface DocumentCorners {
  topLeft: PointF;
  topRight: PointF;
  bottomRight: PointF;
  bottomLeft: PointF;
}

/** Corners covering the full image — the default when detection fails. */
export const FULL_CORNERS: DocumentCorners = {
  topLeft: { x: 0, y: 0 },
  topRight: { x: 1, y: 0 },
  bottomRight: { x: 1, y: 1 },
  bottomLeft: { x: 0, y: 1 },
};

export function cornersToList(c: DocumentCorners): PointF[] {
  return [c.topLeft, c.topRight, c.bottomRight, c.bottomLeft];
}

export function cornersFromList(p: PointF[]): DocumentCorners {
  if (p.length !== 4) throw new Error('DocumentCorners requires exactly 4 points');
  return { topLeft: p[0], topRight: p[1], bottomRight: p[2], bottomLeft: p[3] };
}

/** Image enhancement filters. */
export enum ScanFilter {
  ORIGINAL = 'ORIGINAL',
  MAGIC_COLOR = 'MAGIC_COLOR',
  BLACK_AND_WHITE = 'BLACK_AND_WHITE',
  GRAYSCALE = 'GRAYSCALE',
  HIGH_CONTRAST = 'HIGH_CONTRAST',
}

export const FILTER_LABELS: Record<ScanFilter, string> = {
  [ScanFilter.ORIGINAL]: 'Original',
  [ScanFilter.MAGIC_COLOR]: 'Magic Color',
  [ScanFilter.BLACK_AND_WHITE]: 'Black & White',
  [ScanFilter.GRAYSCALE]: 'Grayscale',
  [ScanFilter.HIGH_CONTRAST]: 'High Contrast',
};

export enum SyncStatus {
  LOCAL_ONLY = 'LOCAL_ONLY',
  PENDING_UPLOAD = 'PENDING_UPLOAD',
  SYNCING = 'SYNCING',
  SYNCED = 'SYNCED',
  ERROR = 'ERROR',
}

/**
 * A page within a document. Image data is stored as Blobs in IndexedDB and referenced by
 * id; `originalBlobId` / `processedBlobId` point into the blob store.
 */
export interface Page {
  id: string;
  documentId: string;
  orderIndex: number;
  originalBlobId: string;
  processedBlobId: string;
  corners: DocumentCorners | null;
  filter: ScanFilter;
  ocrText: string;
  width: number;
  height: number;
}

export interface Tag {
  id: string;
  name: string;
  color?: number | null;
}

export interface Folder {
  id: string;
  name: string;
  parentId: string | null;
  color?: number | null;
  createdAt: number;
  documentCount?: number;
}

export interface Document {
  id: string;
  title: string;
  pages: Page[];
  folderId: string | null;
  tags: Tag[];
  ocrText: string;
  createdAt: number;
  updatedAt: number;
  isFavorite: boolean;
  isLocked: boolean;
  syncStatus: SyncStatus;
}

export function pageCount(doc: Document): number {
  return doc.pages.length;
}

/** An image captured/imported but not yet saved as a Page. */
export interface CapturedImage {
  id: string;
  blob: Blob;
  width: number;
  height: number;
  detectedCorners: DocumentCorners;
}

/** An in-progress, not-yet-persisted page in the active scan session. */
export interface ScanPage {
  id: string;
  original: CapturedImage;
  corners: DocumentCorners;
  filter: ScanFilter;
  processedBlob?: Blob;
  ocrText: string;
}

export interface ScanSession {
  documentTitle: string;
  pages: ScanPage[];
}

export interface OcrBlock {
  text: string;
  boundingBox: { left: number; top: number; right: number; bottom: number };
  confidence: number;
}

export interface OcrResult {
  fullText: string;
  blocks: OcrBlock[];
  languageCode?: string;
}

export enum ThemeMode {
  LIGHT = 'LIGHT',
  DARK = 'DARK',
  SYSTEM = 'SYSTEM',
}

export enum PdfQuality {
  LOW = 50,
  MEDIUM = 75,
  HIGH = 90,
  ORIGINAL = 100,
}

export interface AppSettings {
  themeMode: ThemeMode;
  biometricLockEnabled: boolean;
  pinLockEnabled: boolean;
  defaultFilter: ScanFilter;
  autoEdgeDetection: boolean;
  cloudSyncEnabled: boolean;
  pdfQuality: PdfQuality;
}

export const DEFAULT_SETTINGS: AppSettings = {
  themeMode: ThemeMode.SYSTEM,
  biometricLockEnabled: false,
  pinLockEnabled: false,
  defaultFilter: ScanFilter.MAGIC_COLOR,
  autoEdgeDetection: true,
  cloudSyncEnabled: false,
  pdfQuality: PdfQuality.HIGH,
};
