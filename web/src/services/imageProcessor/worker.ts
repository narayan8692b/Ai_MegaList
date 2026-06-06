/**
 * Image-processing Web Worker.
 *
 * Runs all CPU-heavy pixel work off the main thread on `ImageData` decoded from Blobs via
 * `createImageBitmap` + `OffscreenCanvas`. Communication uses a request-id protocol: the main
 * thread posts `{ id, type, ... }`, the worker replies with `{ id, ok, result }` or
 * `{ id, ok: false, error }`.
 *
 * Operations:
 *  - detectEdges        — heuristic document quadrilateral detection (normalized corners)
 *  - perspectiveCorrect — projective homography warp with bilinear sampling -> JPEG Blob
 *  - applyFilter        — per-pixel enhancement filters -> JPEG Blob
 *  - thumbnail          — downscale -> JPEG Blob
 *  - dimensions         — { width, height }
 *
 * NOTE: this file is loaded as a module worker (Vite `worker.format = 'es'`).
 */

import {
  FULL_CORNERS,
  ScanFilter,
  type DocumentCorners,
  type PointF,
} from '@/domain/models';

/* ------------------------------------------------------------------ */
/* Message protocol                                                    */
/* ------------------------------------------------------------------ */

type DetectEdgesReq = { id: number; type: 'detectEdges'; blob: Blob };
type PerspectiveReq = {
  id: number;
  type: 'perspectiveCorrect';
  blob: Blob;
  corners: DocumentCorners;
};
type ApplyFilterReq = { id: number; type: 'applyFilter'; blob: Blob; filter: ScanFilter };
type ThumbnailReq = { id: number; type: 'thumbnail'; blob: Blob; maxSize: number };
type DimensionsReq = { id: number; type: 'dimensions'; blob: Blob };

type WorkerRequest =
  | DetectEdgesReq
  | PerspectiveReq
  | ApplyFilterReq
  | ThumbnailReq
  | DimensionsReq;

type WorkerResponse =
  | { id: number; ok: true; result: unknown; transfer?: Transferable[] }
  | { id: number; ok: false; error: string };

/* ------------------------------------------------------------------ */
/* Canvas helpers                                                      */
/* ------------------------------------------------------------------ */

/** Decode a Blob to an ImageBitmap (off-main-thread image decode). */
async function decode(blob: Blob): Promise<ImageBitmap> {
  return createImageBitmap(blob);
}

/** Draw a bitmap into an OffscreenCanvas at the given size and return its 2D context. */
function drawToCanvas(
  bmp: ImageBitmap | OffscreenCanvas,
  w: number,
  h: number,
): { canvas: OffscreenCanvas; ctx: OffscreenCanvasRenderingContext2D } {
  const canvas = new OffscreenCanvas(w, h);
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  if (!ctx) throw new Error('Failed to acquire 2D context');
  ctx.drawImage(bmp, 0, 0, w, h);
  return { canvas, ctx };
}

/** Encode an OffscreenCanvas to a JPEG Blob. */
async function toJpeg(canvas: OffscreenCanvas, quality = 0.92): Promise<Blob> {
  return canvas.convertToBlob({ type: 'image/jpeg', quality });
}

/* ------------------------------------------------------------------ */
/* Edge detection (pragmatic heuristic)                                */
/* ------------------------------------------------------------------ */

/**
 * Heuristic document edge detection.
 *
 * Strategy: downscale to a small working buffer, convert to grayscale, compute a Sobel
 * gradient magnitude, threshold it to an "edge-ish" mask, then for each of the four image
 * borders scan inward row/column-by-column to find where strong edge energy first appears
 * (the document boundary against a contrasting background). The four inset borders form an
 * axis-aligned bounding region which is returned as normalized corners.
 *
 * This is intentionally simple and robust rather than a full contour/quadrilateral fit. If
 * confidence is low (little edge energy, or the detected inset is implausibly small) we fall
 * back to FULL_CORNERS.
 *
 * PRODUCTION NOTE: for true skewed-quadrilateral detection, swap this for OpenCV.js
 * (findContours + approxPolyDP) or jscanify. The public contract (normalized DocumentCorners)
 * stays identical.
 */
function detectEdges(bmp: ImageBitmap): DocumentCorners {
  const MAX = 320;
  const scale = Math.min(1, MAX / Math.max(bmp.width, bmp.height));
  const w = Math.max(1, Math.round(bmp.width * scale));
  const h = Math.max(1, Math.round(bmp.height * scale));

  const { ctx } = drawToCanvas(bmp, w, h);
  const { data } = ctx.getImageData(0, 0, w, h);

  // Grayscale buffer.
  const gray = new Float32Array(w * h);
  for (let i = 0, p = 0; i < data.length; i += 4, p++) {
    gray[p] = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
  }

  // Sobel gradient magnitude.
  const mag = new Float32Array(w * h);
  let maxMag = 0;
  for (let y = 1; y < h - 1; y++) {
    for (let x = 1; x < w - 1; x++) {
      const idx = y * w + x;
      const gx =
        -gray[idx - w - 1] - 2 * gray[idx - 1] - gray[idx + w - 1] +
        gray[idx - w + 1] + 2 * gray[idx + 1] + gray[idx + w + 1];
      const gy =
        -gray[idx - w - 1] - 2 * gray[idx - w] - gray[idx - w + 1] +
        gray[idx + w - 1] + 2 * gray[idx + w] + gray[idx + w + 1];
      const m = Math.hypot(gx, gy);
      mag[idx] = m;
      if (m > maxMag) maxMag = m;
    }
  }
  if (maxMag <= 1e-3) return FULL_CORNERS;

  const threshold = maxMag * 0.35;

  // For a given row, count strong-edge pixels.
  const rowEnergy = (y: number): number => {
    let c = 0;
    for (let x = 0; x < w; x++) if (mag[y * w + x] > threshold) c++;
    return c;
  };
  const colEnergy = (x: number): number => {
    let c = 0;
    for (let y = 0; y < h; y++) if (mag[y * w + x] > threshold) c++;
    return c;
  };

  const rowMin = Math.max(2, Math.round(w * 0.04));
  const colMin = Math.max(2, Math.round(h * 0.04));

  // Scan inward from each border until we hit a row/col with significant edge energy.
  const limitV = Math.floor(h * 0.45);
  const limitH = Math.floor(w * 0.45);

  let top = 0;
  for (let y = 0; y < limitV; y++) {
    if (rowEnergy(y) >= rowMin) { top = y; break; }
  }
  let bottom = h - 1;
  for (let y = h - 1; y > h - 1 - limitV; y--) {
    if (rowEnergy(y) >= rowMin) { bottom = y; break; }
  }
  let left = 0;
  for (let x = 0; x < limitH; x++) {
    if (colEnergy(x) >= colMin) { left = x; break; }
  }
  let right = w - 1;
  for (let x = w - 1; x > w - 1 - limitH; x--) {
    if (colEnergy(x) >= colMin) { right = x; break; }
  }

  // Plausibility: detected region must cover a meaningful fraction of the image.
  const insetW = (right - left) / w;
  const insetH = (bottom - top) / h;
  if (insetW < 0.4 || insetH < 0.4) return FULL_CORNERS;

  const nl = left / (w - 1);
  const nt = top / (h - 1);
  const nr = right / (w - 1);
  const nb = bottom / (h - 1);

  return {
    topLeft: { x: nl, y: nt },
    topRight: { x: nr, y: nt },
    bottomRight: { x: nr, y: nb },
    bottomLeft: { x: nl, y: nb },
  };
}

/* ------------------------------------------------------------------ */
/* Perspective correction (homography + bilinear warp)                 */
/* ------------------------------------------------------------------ */

/**
 * Solve an 8x8 linear system A·x = b via Gaussian elimination with partial pivoting.
 * Returns the 8-vector solution.
 */
function solveLinearSystem(A: number[][], b: number[]): number[] {
  const n = b.length;
  // Augmented matrix.
  const M: number[][] = A.map((row, i) => [...row, b[i]]);

  for (let col = 0; col < n; col++) {
    // Partial pivot.
    let pivot = col;
    for (let r = col + 1; r < n; r++) {
      if (Math.abs(M[r][col]) > Math.abs(M[pivot][col])) pivot = r;
    }
    if (Math.abs(M[pivot][col]) < 1e-12) {
      throw new Error('Singular matrix in homography solve');
    }
    [M[col], M[pivot]] = [M[pivot], M[col]];

    // Eliminate below + above.
    for (let r = 0; r < n; r++) {
      if (r === col) continue;
      const factor = M[r][col] / M[col][col];
      if (factor === 0) continue;
      for (let c = col; c <= n; c++) M[r][c] -= factor * M[col][c];
    }
  }

  const x = new Array<number>(n);
  for (let i = 0; i < n; i++) x[i] = M[i][n] / M[i][i];
  return x;
}

/**
 * Compute the 3x3 homography H mapping src points -> dst points.
 *
 * For each correspondence (sx,sy)->(dx,dy) we get two equations in the 8 unknowns
 * (h0..h7), fixing h8 = 1. Returns H as a flat 9-element array (row-major).
 */
function computeHomography(src: PointF[], dst: PointF[]): number[] {
  const A: number[][] = [];
  const b: number[] = [];
  for (let i = 0; i < 4; i++) {
    const { x: sx, y: sy } = src[i];
    const { x: dx, y: dy } = dst[i];
    A.push([sx, sy, 1, 0, 0, 0, -dx * sx, -dx * sy]);
    b.push(dx);
    A.push([0, 0, 0, sx, sy, 1, -dy * sx, -dy * sy]);
    b.push(dy);
  }
  const h = solveLinearSystem(A, b);
  return [h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7], 1];
}

/** Invert a 3x3 matrix (row-major flat array). */
function invert3x3(m: number[]): number[] {
  const [a, b, c, d, e, f, g, h, i] = m;
  const A = e * i - f * h;
  const B = -(d * i - f * g);
  const C = d * h - e * g;
  const det = a * A + b * B + c * C;
  if (Math.abs(det) < 1e-12) throw new Error('Singular homography');
  const invDet = 1 / det;
  return [
    A * invDet,
    (c * h - b * i) * invDet,
    (b * f - c * e) * invDet,
    B * invDet,
    (a * i - c * g) * invDet,
    (c * d - a * f) * invDet,
    C * invDet,
    (b * g - a * h) * invDet,
    (a * e - b * d) * invDet,
  ];
}

function dist(a: PointF, b: PointF): number {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

/**
 * Warp the quadrilateral described by `corners` (normalized) in `bmp` to an axis-aligned
 * output rectangle using a projective homography and bilinear inverse sampling.
 */
function perspectiveCorrect(bmp: ImageBitmap, corners: DocumentCorners): OffscreenCanvas {
  const iw = bmp.width;
  const ih = bmp.height;

  // Source corners in pixel space (clockwise from top-left).
  const tl = { x: corners.topLeft.x * iw, y: corners.topLeft.y * ih };
  const tr = { x: corners.topRight.x * iw, y: corners.topRight.y * ih };
  const br = { x: corners.bottomRight.x * iw, y: corners.bottomRight.y * ih };
  const bl = { x: corners.bottomLeft.x * iw, y: corners.bottomLeft.y * ih };

  // Estimate output size from average opposing edge lengths.
  const widthTop = dist(tl, tr);
  const widthBottom = dist(bl, br);
  const heightLeft = dist(tl, bl);
  const heightRight = dist(tr, br);

  const MAX_SIDE = 2000;
  let outW = Math.round((widthTop + widthBottom) / 2);
  let outH = Math.round((heightLeft + heightRight) / 2);
  outW = Math.max(1, outW);
  outH = Math.max(1, outH);

  // Clamp the longest side to keep memory/CPU bounded.
  const longest = Math.max(outW, outH);
  if (longest > MAX_SIDE) {
    const k = MAX_SIDE / longest;
    outW = Math.max(1, Math.round(outW * k));
    outH = Math.max(1, Math.round(outH * k));
  }

  const src: PointF[] = [tl, tr, br, bl];
  const dst: PointF[] = [
    { x: 0, y: 0 },
    { x: outW - 1, y: 0 },
    { x: outW - 1, y: outH - 1 },
    { x: 0, y: outH - 1 },
  ];

  // We map dst -> src for inverse sampling.
  const H = computeHomography(src, dst);
  const Hinv = invert3x3(H);

  // Read source pixels.
  const { ctx: srcCtx } = drawToCanvas(bmp, iw, ih);
  const srcData = srcCtx.getImageData(0, 0, iw, ih).data;

  const out = new OffscreenCanvas(outW, outH);
  const outCtx = out.getContext('2d');
  if (!outCtx) throw new Error('Failed to acquire output 2D context');
  const outImg = outCtx.createImageData(outW, outH);
  const od = outImg.data;

  const [m0, m1, m2, m3, m4, m5, m6, m7, m8] = Hinv;

  for (let y = 0; y < outH; y++) {
    for (let x = 0; x < outW; x++) {
      // Apply inverse homography to find source coordinate.
      const denom = m6 * x + m7 * y + m8;
      const sx = (m0 * x + m1 * y + m2) / denom;
      const sy = (m3 * x + m4 * y + m5) / denom;

      const oi = (y * outW + x) * 4;

      if (sx < 0 || sy < 0 || sx > iw - 1 || sy > ih - 1) {
        od[oi] = 255; od[oi + 1] = 255; od[oi + 2] = 255; od[oi + 3] = 255;
        continue;
      }

      // Bilinear interpolation.
      const x0 = Math.floor(sx);
      const y0 = Math.floor(sy);
      const x1 = Math.min(x0 + 1, iw - 1);
      const y1 = Math.min(y0 + 1, ih - 1);
      const fx = sx - x0;
      const fy = sy - y0;

      const i00 = (y0 * iw + x0) * 4;
      const i10 = (y0 * iw + x1) * 4;
      const i01 = (y1 * iw + x0) * 4;
      const i11 = (y1 * iw + x1) * 4;

      const w00 = (1 - fx) * (1 - fy);
      const w10 = fx * (1 - fy);
      const w01 = (1 - fx) * fy;
      const w11 = fx * fy;

      for (let ch = 0; ch < 3; ch++) {
        od[oi + ch] =
          srcData[i00 + ch] * w00 +
          srcData[i10 + ch] * w10 +
          srcData[i01 + ch] * w01 +
          srcData[i11 + ch] * w11;
      }
      od[oi + 3] = 255;
    }
  }

  outCtx.putImageData(outImg, 0, 0);
  return out;
}

/* ------------------------------------------------------------------ */
/* Filters                                                             */
/* ------------------------------------------------------------------ */

/** Compute an Otsu threshold (0..255) for a grayscale histogram. */
function otsuThreshold(hist: number[], total: number): number {
  let sum = 0;
  for (let t = 0; t < 256; t++) sum += t * hist[t];

  let sumB = 0;
  let wB = 0;
  let maxVar = 0;
  let threshold = 127;
  for (let t = 0; t < 256; t++) {
    wB += hist[t];
    if (wB === 0) continue;
    const wF = total - wB;
    if (wF === 0) break;
    sumB += t * hist[t];
    const mB = sumB / wB;
    const mF = (sum - sumB) / wF;
    const between = wB * wF * (mB - mF) * (mB - mF);
    if (between > maxVar) {
      maxVar = between;
      threshold = t;
    }
  }
  return threshold;
}

function clamp8(v: number): number {
  return v < 0 ? 0 : v > 255 ? 255 : v;
}

/** Apply the requested enhancement filter to ImageData in place. */
function applyFilterToImageData(img: ImageData, filter: ScanFilter): void {
  const d = img.data;
  const n = d.length;

  switch (filter) {
    case ScanFilter.ORIGINAL:
      return;

    case ScanFilter.GRAYSCALE: {
      for (let i = 0; i < n; i += 4) {
        const g = clamp8(0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2]);
        d[i] = d[i + 1] = d[i + 2] = g;
      }
      return;
    }

    case ScanFilter.BLACK_AND_WHITE: {
      // Grayscale -> Otsu threshold -> pure black/white.
      const hist = new Array<number>(256).fill(0);
      const gray = new Uint8ClampedArray(n / 4);
      for (let i = 0, p = 0; i < n; i += 4, p++) {
        const g = Math.round(0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2]);
        gray[p] = g;
        hist[g]++;
      }
      const t = otsuThreshold(hist, n / 4);
      for (let i = 0, p = 0; i < n; i += 4, p++) {
        const v = gray[p] > t ? 255 : 0;
        d[i] = d[i + 1] = d[i + 2] = v;
      }
      return;
    }

    case ScanFilter.HIGH_CONTRAST: {
      // Contrast stretch: find 2nd/98th percentiles per luminance and remap.
      const hist = new Array<number>(256).fill(0);
      for (let i = 0; i < n; i += 4) {
        const g = Math.round(0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2]);
        hist[g]++;
      }
      const total = n / 4;
      const lowCut = total * 0.02;
      const highCut = total * 0.98;
      let acc = 0;
      let lo = 0;
      let hi = 255;
      for (let v = 0; v < 256; v++) {
        acc += hist[v];
        if (acc >= lowCut) { lo = v; break; }
      }
      acc = 0;
      for (let v = 0; v < 256; v++) {
        acc += hist[v];
        if (acc >= highCut) { hi = v; break; }
      }
      const range = Math.max(1, hi - lo);
      for (let i = 0; i < n; i += 4) {
        d[i] = clamp8(((d[i] - lo) / range) * 255);
        d[i + 1] = clamp8(((d[i + 1] - lo) / range) * 255);
        d[i + 2] = clamp8(((d[i + 2] - lo) / range) * 255);
      }
      return;
    }

    case ScanFilter.MAGIC_COLOR: {
      // Document enhancement: simple gray-world white balance, then brightness +
      // contrast + saturation boost to make paper crisp and white.
      let sumR = 0;
      let sumG = 0;
      let sumB = 0;
      const px = n / 4;
      for (let i = 0; i < n; i += 4) {
        sumR += d[i];
        sumG += d[i + 1];
        sumB += d[i + 2];
      }
      const avgR = sumR / px;
      const avgG = sumG / px;
      const avgB = sumB / px;
      const avgGray = (avgR + avgG + avgB) / 3;
      const kR = avgGray / (avgR || 1);
      const kG = avgGray / (avgG || 1);
      const kB = avgGray / (avgB || 1);

      const contrast = 1.25; // >1 increases contrast
      const brightness = 12; // additive
      const saturation = 1.15;

      for (let i = 0; i < n; i += 4) {
        // White balance.
        let r = d[i] * kR;
        let g = d[i + 1] * kG;
        let b = d[i + 2] * kB;

        // Brightness + contrast around mid-gray.
        r = (r - 128) * contrast + 128 + brightness;
        g = (g - 128) * contrast + 128 + brightness;
        b = (b - 128) * contrast + 128 + brightness;

        // Saturation around luminance.
        const lum = 0.299 * r + 0.587 * g + 0.114 * b;
        r = lum + (r - lum) * saturation;
        g = lum + (g - lum) * saturation;
        b = lum + (b - lum) * saturation;

        d[i] = clamp8(r);
        d[i + 1] = clamp8(g);
        d[i + 2] = clamp8(b);
      }
      return;
    }
  }
}

/* ------------------------------------------------------------------ */
/* Operation dispatch                                                  */
/* ------------------------------------------------------------------ */

async function handleDetectEdges(req: DetectEdgesReq): Promise<DocumentCorners> {
  const bmp = await decode(req.blob);
  try {
    return detectEdges(bmp);
  } finally {
    bmp.close();
  }
}

async function handlePerspective(req: PerspectiveReq): Promise<Blob> {
  const bmp = await decode(req.blob);
  try {
    const canvas = perspectiveCorrect(bmp, req.corners);
    return toJpeg(canvas, 0.92);
  } finally {
    bmp.close();
  }
}

async function handleApplyFilter(req: ApplyFilterReq): Promise<Blob> {
  const bmp = await decode(req.blob);
  try {
    const { canvas, ctx } = drawToCanvas(bmp, bmp.width, bmp.height);
    const img = ctx.getImageData(0, 0, bmp.width, bmp.height);
    applyFilterToImageData(img, req.filter);
    ctx.putImageData(img, 0, 0);
    return toJpeg(canvas, 0.92);
  } finally {
    bmp.close();
  }
}

async function handleThumbnail(req: ThumbnailReq): Promise<Blob> {
  const bmp = await decode(req.blob);
  try {
    const scale = Math.min(1, req.maxSize / Math.max(bmp.width, bmp.height));
    const w = Math.max(1, Math.round(bmp.width * scale));
    const h = Math.max(1, Math.round(bmp.height * scale));
    const { canvas } = drawToCanvas(bmp, w, h);
    return toJpeg(canvas, 0.8);
  } finally {
    bmp.close();
  }
}

async function handleDimensions(req: DimensionsReq): Promise<{ width: number; height: number }> {
  const bmp = await decode(req.blob);
  const dims = { width: bmp.width, height: bmp.height };
  bmp.close();
  return dims;
}

self.onmessage = async (e: MessageEvent<WorkerRequest>) => {
  const req = e.data;
  try {
    let result: unknown;
    switch (req.type) {
      case 'detectEdges':
        result = await handleDetectEdges(req);
        break;
      case 'perspectiveCorrect':
        result = await handlePerspective(req);
        break;
      case 'applyFilter':
        result = await handleApplyFilter(req);
        break;
      case 'thumbnail':
        result = await handleThumbnail(req);
        break;
      case 'dimensions':
        result = await handleDimensions(req);
        break;
      default: {
        const _exhaustive: never = req;
        throw new Error(`Unknown request: ${JSON.stringify(_exhaustive)}`);
      }
    }
    const response: WorkerResponse = { id: req.id, ok: true, result };
    (self as unknown as Worker).postMessage(response);
  } catch (err) {
    const response: WorkerResponse = {
      id: req.id,
      ok: false,
      error: err instanceof Error ? err.message : String(err),
    };
    (self as unknown as Worker).postMessage(response);
  }
};
