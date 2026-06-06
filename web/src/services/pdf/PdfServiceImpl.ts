/**
 * `PdfService` implementation backed by jsPDF + canvas.
 *
 * `generatePdf` lays out one image per page, sizing each page (in points) to the image's
 * aspect ratio so scanned documents are not distorted or letterboxed. `exportJpg` re-encodes
 * a single image to JPEG at the requested quality via a canvas.
 */
import { jsPDF } from 'jspdf';
import { PdfQuality } from '@/domain/models';
import type { PdfService } from '@/domain/services';

/** Quality enum value (50/75/90/100) → jsPDF/canvas 0..1 quality factor. */
function qualityFactor(q: PdfQuality): number {
  return q / 100;
}

export class PdfServiceImpl implements PdfService {
  /**
   * Build a multi-page PDF from image blobs. Each page is sized to the image aspect (unit
   * 'pt') and the image fills the page. Pages are added sequentially and source bitmaps are
   * released as we go to keep memory bounded for large documents.
   *
   * `password` enables jsPDF's built-in encryption. NOTE: jsPDF uses 40-bit RC4 encryption,
   * which is weak/legacy and only deters casual access — it is NOT strong protection.
   */
  async generatePdf(
    blobs: Blob[],
    quality: PdfQuality = PdfQuality.HIGH,
    password?: string,
  ): Promise<Blob> {
    if (blobs.length === 0) throw new Error('generatePdf requires at least one image');

    const factor = qualityFactor(quality);

    // First image determines the initial page; jsPDF needs an orientation/format up front.
    const first = await loadImage(blobs[0]);
    const doc = new jsPDF({
      unit: 'pt',
      orientation: first.width >= first.height ? 'landscape' : 'portrait',
      format: [first.width, first.height],
      compress: true,
      ...(password
        ? { encryption: { userPassword: password, ownerPassword: password } }
        : {}),
    });

    addImageToPage(doc, first, factor, true);
    releaseImage(first);

    for (let i = 1; i < blobs.length; i++) {
      const img = await loadImage(blobs[i]);
      doc.addPage(
        [img.width, img.height],
        img.width >= img.height ? 'landscape' : 'portrait',
      );
      addImageToPage(doc, img, factor, false);
      releaseImage(img);
    }

    return doc.output('blob');
  }

  /** Re-encode a single image to JPEG at the requested quality. */
  async exportJpg(blob: Blob, quality: PdfQuality = PdfQuality.HIGH): Promise<Blob> {
    const img = await loadImage(blob);
    try {
      const canvas = document.createElement('canvas');
      canvas.width = img.width;
      canvas.height = img.height;
      const ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('Failed to acquire 2D context for JPG export');
      ctx.drawImage(img.el, 0, 0);
      return await canvasToJpeg(canvas, qualityFactor(quality));
    } finally {
      releaseImage(img);
    }
  }
}

/* ------------------------------------------------------------------ */
/* Image loading helpers                                               */
/* ------------------------------------------------------------------ */

interface LoadedImage {
  el: HTMLImageElement;
  url: string;
  width: number;
  height: number;
}

/** Load a Blob into an HTMLImageElement via an object URL (revoked on release). */
function loadImage(blob: Blob): Promise<LoadedImage> {
  return new Promise<LoadedImage>((resolve, reject) => {
    const url = URL.createObjectURL(blob);
    const el = new Image();
    el.onload = () =>
      resolve({ el, url, width: el.naturalWidth, height: el.naturalHeight });
    el.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Failed to decode image for PDF'));
    };
    el.src = url;
  });
}

function releaseImage(img: LoadedImage): void {
  URL.revokeObjectURL(img.url);
}

/**
 * Draw the loaded image onto a page filling its full extent. The page was created at the
 * image's pixel size in points, so the image maps 1:1 to the page rectangle.
 */
function addImageToPage(
  doc: jsPDF,
  img: LoadedImage,
  quality: number,
  _isFirst: boolean,
): void {
  const pageW = doc.internal.pageSize.getWidth();
  const pageH = doc.internal.pageSize.getHeight();
  // Re-encode to JPEG at the requested quality before embedding to control file size.
  const dataUrl = toJpegDataUrl(img, quality);
  doc.addImage(dataUrl, 'JPEG', 0, 0, pageW, pageH, undefined, 'FAST');
}

/** Render an image to a canvas and return a JPEG data URL at the given quality. */
function toJpegDataUrl(img: LoadedImage, quality: number): string {
  const canvas = document.createElement('canvas');
  canvas.width = img.width;
  canvas.height = img.height;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Failed to acquire 2D context for PDF image');
  ctx.drawImage(img.el, 0, 0);
  return canvas.toDataURL('image/jpeg', quality);
}

/** Encode a canvas to a JPEG Blob. */
function canvasToJpeg(canvas: HTMLCanvasElement, quality: number): Promise<Blob> {
  return new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error('Canvas toBlob returned null'))),
      'image/jpeg',
      quality,
    );
  });
}
