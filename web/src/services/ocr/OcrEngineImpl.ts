/**
 * `OcrEngine` implementation backed by Tesseract.js (v5).
 *
 * A single Tesseract worker is created lazily and cached for the lifetime of the engine
 * (worker spin-up + language-data download is expensive, so we reuse it across recognitions).
 * Recognition results are mapped to the domain `OcrResult`, with word-level blocks carrying
 * bounding boxes normalized (0..1) against the recognized image dimensions.
 */
import { createWorker, type Worker } from 'tesseract.js';
import type { OcrBlock, OcrResult } from '@/domain/models';
import type { OcrEngine } from '@/domain/services';

export class OcrEngineImpl implements OcrEngine {
  private workerPromise: Promise<Worker> | null = null;

  constructor(private readonly language = 'eng') {}

  /** Lazily create (and cache) the Tesseract worker. v5 `createWorker` resolves a ready worker. */
  private getWorker(): Promise<Worker> {
    if (!this.workerPromise) {
      this.workerPromise = createWorker(this.language);
    }
    return this.workerPromise;
  }

  async recognize(blob: Blob): Promise<OcrResult> {
    const worker = await this.getWorker();
    // Tesseract.js accepts a Blob directly as the image source.
    const { data } = await worker.recognize(blob);

    // Recognized image dimensions used to normalize bounding boxes. Fall back to 1 to avoid
    // division by zero if a backend omits them.
    const imgW = (data as { imageWidth?: number }).imageWidth || 1;
    const imgH = (data as { imageHeight?: number }).imageHeight || 1;

    const words: TesseractWord[] = data.words ?? collectWords(data);
    const blocks: OcrBlock[] = words
      .filter((w) => w.text && w.text.trim().length > 0)
      .map((w) => ({
        text: w.text,
        boundingBox: {
          left: w.bbox.x0 / imgW,
          top: w.bbox.y0 / imgH,
          right: w.bbox.x1 / imgW,
          bottom: w.bbox.y1 / imgH,
        },
        confidence: w.confidence,
      }));

    return {
      fullText: data.text ?? '',
      blocks,
      languageCode: this.language,
    };
  }

  /** Terminate the cached worker and release its resources (optional teardown). */
  async dispose(): Promise<void> {
    if (this.workerPromise) {
      const worker = await this.workerPromise.catch(() => null);
      this.workerPromise = null;
      await worker?.terminate();
    }
  }
}

/* ------------------------------------------------------------------ */
/* Tesseract result shapes (minimal, to avoid `any`)                   */
/* ------------------------------------------------------------------ */

interface BBox {
  x0: number;
  y0: number;
  x1: number;
  y1: number;
}

interface TesseractWord {
  text: string;
  confidence: number;
  bbox: BBox;
}

interface TesseractLine {
  words?: TesseractWord[];
}

/**
 * Some Tesseract.js builds only populate `lines` (not a top-level `words` array) depending on
 * the output flags. Flatten line→words as a fallback so we always get word-level blocks.
 */
function collectWords(data: { lines?: TesseractLine[] }): TesseractWord[] {
  const out: TesseractWord[] = [];
  for (const line of data.lines ?? []) {
    for (const w of line.words ?? []) out.push(w);
  }
  return out;
}
