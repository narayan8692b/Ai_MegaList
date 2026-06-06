/**
 * Service container — the composition root. Bundles every repository + service behind a
 * single object that the React app provides via context. Implementations are wired in
 * `createServices()` (see `container.impl.ts`).
 */
import type {
  CameraService,
  DocumentRepository,
  FolderRepository,
  IdGenerator,
  ImageProcessor,
  OcrEngine,
  PdfService,
  SettingsRepository,
  ShareService,
} from '@/domain/services';

export interface Services {
  documents: DocumentRepository;
  folders: FolderRepository;
  settings: SettingsRepository;
  camera: CameraService;
  imageProcessor: ImageProcessor;
  ocr: OcrEngine;
  pdf: PdfService;
  share: ShareService;
  ids: IdGenerator;
}
