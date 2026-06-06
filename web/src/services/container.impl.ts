/**
 * Composition root. This is the ONLY module that imports both the data layer and the
 * service implementations, wiring them into the single `Services` object that the rest of
 * the app consumes via `ServicesProvider` / `useServices()`.
 */
import type { Services } from './container';
import { createDataLayer } from '@/data/createDataLayer';
import {
  createCameraService,
  createImageProcessor,
  createOcrEngine,
  createPdfService,
  createShareService,
} from '@/services/impl';

export async function createServices(): Promise<Services> {
  const data = await createDataLayer();

  return {
    documents: data.documents,
    folders: data.folders,
    settings: data.settings,
    ids: data.ids,
    camera: createCameraService(),
    imageProcessor: createImageProcessor(),
    ocr: createOcrEngine(),
    pdf: createPdfService(),
    share: createShareService(),
  };
}
