/**
 * Browser-native `CameraService` implementation.
 *
 * Uses `getUserMedia` for a live preview stream and a still-frame capture, plus a hidden
 * file `<input>` for gallery / "take photo" imports. Edge detection for every captured or
 * imported image is delegated to an injected `ImageProcessor` (which runs the heavy work in
 * a Web Worker), so the camera service stays free of pixel math.
 */
import { FULL_CORNERS, type CapturedImage } from '@/domain/models';
import type { CameraService, ImageProcessor } from '@/domain/services';

export class CameraServiceImpl implements CameraService {
  constructor(private readonly imageProcessor: ImageProcessor) {}

  /** True when the browser exposes a camera-capable `getUserMedia`. */
  async isCameraAvailable(): Promise<boolean> {
    return !!navigator.mediaDevices?.getUserMedia;
  }

  /**
   * Start a live stream into the given `<video>` and begin playback. Returns a stop function
   * that detaches the stream and stops every track (releasing the camera LED/hardware).
   */
  async startStream(
    video: HTMLVideoElement,
    facingMode: 'environment' | 'user' = 'environment',
  ): Promise<() => void> {
    if (!navigator.mediaDevices?.getUserMedia) {
      throw new Error('Camera not available in this browser');
    }

    const stream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode,
        width: { ideal: 1920 },
        height: { ideal: 1080 },
      },
      audio: false,
    });

    video.srcObject = stream;
    // `playsInline` is required so iOS Safari renders inline instead of fullscreen.
    video.setAttribute('playsinline', 'true');
    video.muted = true;

    // Wait for intrinsic dimensions to be known before allowing capture.
    await new Promise<void>((resolve) => {
      if (video.readyState >= 1 /* HAVE_METADATA */) {
        resolve();
        return;
      }
      const onMeta = () => {
        video.removeEventListener('loadedmetadata', onMeta);
        resolve();
      };
      video.addEventListener('loadedmetadata', onMeta);
    });

    try {
      await video.play();
    } catch {
      // Autoplay may be rejected until a user gesture; the stream is still attached.
    }

    return () => {
      for (const track of stream.getTracks()) track.stop();
      if (video.srcObject === stream) video.srcObject = null;
    };
  }

  /**
   * Grab the current video frame at the video's intrinsic resolution, encode JPEG, and run
   * edge detection to populate `detectedCorners` (falling back to FULL_CORNERS).
   */
  async capture(video: HTMLVideoElement): Promise<CapturedImage> {
    const width = video.videoWidth;
    const height = video.videoHeight;
    if (!width || !height) {
      throw new Error('Video stream has no frame to capture yet');
    }

    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    if (!ctx) throw new Error('Failed to acquire 2D context for capture');
    ctx.drawImage(video, 0, 0, width, height);

    const blob = await canvasToJpeg(canvas, 0.92);
    const detectedCorners = await this.detect(blob);

    return {
      id: crypto.randomUUID(),
      blob,
      width,
      height,
      detectedCorners,
    };
  }

  /**
   * Import image(s) via a hidden file input. On iOS the `accept="image/*"` input also offers
   * the camera as a source. Each chosen file is decoded for its dimensions and run through
   * edge detection before being returned as a `CapturedImage`.
   */
  async pickFromGallery(allowMultiple = true): Promise<CapturedImage[]> {
    const files = await this.openFilePicker(allowMultiple);
    const out: CapturedImage[] = [];
    for (const file of files) {
      const { width, height } = await this.imageProcessor.dimensions(file);
      const detectedCorners = await this.detect(file);
      out.push({
        id: crypto.randomUUID(),
        blob: file,
        width,
        height,
        detectedCorners,
      });
    }
    return out;
  }

  /** Run edge detection, falling back to full-frame corners on any failure. */
  private async detect(blob: Blob): Promise<CapturedImage['detectedCorners']> {
    try {
      return await this.imageProcessor.detectEdges(blob);
    } catch {
      return FULL_CORNERS;
    }
  }

  /** Create, click, and tear down a transient `<input type="file">`; resolve with picked files. */
  private openFilePicker(allowMultiple: boolean): Promise<File[]> {
    return new Promise<File[]>((resolve) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = 'image/*';
      input.multiple = allowMultiple;
      input.style.position = 'fixed';
      input.style.left = '-9999px';

      let settled = false;
      const cleanup = () => {
        input.removeEventListener('change', onChange);
        window.removeEventListener('focus', onFocus, true);
        input.remove();
      };
      const finish = (files: File[]) => {
        if (settled) return;
        settled = true;
        cleanup();
        resolve(files);
      };

      const onChange = () => {
        finish(input.files ? Array.from(input.files) : []);
      };
      // If the user cancels the dialog, `change` never fires; detect the returning focus to
      // resolve with an empty selection rather than hanging forever.
      const onFocus = () => {
        // Defer: the `change` event (if any) fires shortly after focus returns.
        setTimeout(() => {
          if (!settled && (!input.files || input.files.length === 0)) finish([]);
        }, 300);
      };

      input.addEventListener('change', onChange);
      window.addEventListener('focus', onFocus, true);

      document.body.appendChild(input);
      input.click();
    });
  }
}

/** Encode a canvas to a JPEG Blob, rejecting if encoding fails. */
function canvasToJpeg(canvas: HTMLCanvasElement, quality: number): Promise<Blob> {
  return new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error('Canvas toBlob returned null'))),
      'image/jpeg',
      quality,
    );
  });
}
