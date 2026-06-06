/**
 * Service implementation factories consumed by the app composition root
 * (`@/services/container.impl`). These are the only entry points the rest of the app uses to
 * obtain concrete browser-native service implementations.
 */
import type {
  CameraService,
  ImageProcessor,
  OcrEngine,
  PdfService,
  ShareService,
} from '@/domain/services';
import { CameraServiceImpl } from '@/services/camera/CameraServiceImpl';
import { ImageProcessorImpl } from '@/services/imageProcessor/ImageProcessorImpl';
import { OcrEngineImpl } from '@/services/ocr/OcrEngineImpl';
import { PdfServiceImpl } from '@/services/pdf/PdfServiceImpl';
import { ShareServiceImpl } from '@/services/share/ShareServiceImpl';

/**
 * Shared, lazily-created ImageProcessor singleton. The image worker is relatively expensive
 * to spin up, and both the standalone processor and the camera service need one — sharing a
 * single instance avoids running two workers.
 */
let sharedImageProcessor: ImageProcessorImpl | null = null;

function getSharedImageProcessor(): ImageProcessorImpl {
  if (!sharedImageProcessor) sharedImageProcessor = new ImageProcessorImpl();
  return sharedImageProcessor;
}

export function createImageProcessor(): ImageProcessor {
  return getSharedImageProcessor();
}

export function createCameraService(): CameraService {
  return new CameraServiceImpl(getSharedImageProcessor());
}

export function createOcrEngine(): OcrEngine {
  return new OcrEngineImpl();
}

export function createPdfService(): PdfService {
  return new PdfServiceImpl();
}

export function createShareService(): ShareService {
  return new ShareServiceImpl();
}
