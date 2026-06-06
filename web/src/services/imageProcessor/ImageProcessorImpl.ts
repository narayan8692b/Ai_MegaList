/**
 * Main-thread `ImageProcessor` implementation.
 *
 * Lazily spins up the image-processing Web Worker and exposes promise-based methods that
 * post request-id-tagged messages and resolve when the matching response arrives. The worker
 * does all CPU-heavy pixel work (edge detection, perspective warp, filters, thumbnails).
 */
import type { DocumentCorners, ScanFilter } from '@/domain/models';
import type { ImageProcessor } from '@/domain/services';

interface PendingResolvers {
  resolve: (value: unknown) => void;
  reject: (reason: Error) => void;
}

type WorkerResponse =
  | { id: number; ok: true; result: unknown }
  | { id: number; ok: false; error: string };

export class ImageProcessorImpl implements ImageProcessor {
  private worker: Worker | null = null;
  private nextId = 1;
  private readonly pending = new Map<number, PendingResolvers>();

  /** Lazily create the module worker on first use. */
  private getWorker(): Worker {
    if (this.worker) return this.worker;

    const worker = new Worker(new URL('./worker.ts', import.meta.url), {
      type: 'module',
    });

    worker.onmessage = (e: MessageEvent<WorkerResponse>) => {
      const msg = e.data;
      const entry = this.pending.get(msg.id);
      if (!entry) return;
      this.pending.delete(msg.id);
      if (msg.ok) entry.resolve(msg.result);
      else entry.reject(new Error(msg.error));
    };

    worker.onerror = (e) => {
      // Fail all in-flight requests so callers don't hang.
      const err = new Error(e.message || 'Image worker error');
      for (const [, entry] of this.pending) entry.reject(err);
      this.pending.clear();
    };

    this.worker = worker;
    return worker;
  }

  /** Post a typed request and await the matching response by id. */
  private request<T>(
    type: string,
    payload: Record<string, unknown>,
    transfer: Transferable[] = [],
  ): Promise<T> {
    const worker = this.getWorker();
    const id = this.nextId++;
    return new Promise<T>((resolve, reject) => {
      this.pending.set(id, {
        resolve: resolve as (v: unknown) => void,
        reject,
      });
      worker.postMessage({ id, type, ...payload }, transfer);
    });
  }

  detectEdges(blob: Blob): Promise<DocumentCorners> {
    return this.request<DocumentCorners>('detectEdges', { blob });
  }

  perspectiveCorrect(blob: Blob, corners: DocumentCorners): Promise<Blob> {
    return this.request<Blob>('perspectiveCorrect', { blob, corners });
  }

  applyFilter(blob: Blob, filter: ScanFilter): Promise<Blob> {
    return this.request<Blob>('applyFilter', { blob, filter });
  }

  createThumbnail(blob: Blob, maxSize = 256): Promise<Blob> {
    return this.request<Blob>('thumbnail', { blob, maxSize });
  }

  dimensions(blob: Blob): Promise<{ width: number; height: number }> {
    return this.request<{ width: number; height: number }>('dimensions', { blob });
  }

  /** Tear down the worker (optional; e.g. on app teardown). */
  dispose(): void {
    this.worker?.terminate();
    this.worker = null;
    this.pending.clear();
  }
}
