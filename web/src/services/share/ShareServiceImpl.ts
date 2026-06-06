/**
 * `ShareService` implementation using the Web Share API with a download fallback.
 *
 * `share` attempts `navigator.share({ files })` (level 2 Web Share); if the API is missing,
 * the file type is unshareable, or the user/agent aborts, it falls back to a plain download.
 */
import type { ShareService } from '@/domain/services';

export class ShareServiceImpl implements ShareService {
  /** Trigger a file download via a transient `<a download>` and an object URL. */
  download(blob: Blob, filename: string): void {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.rel = 'noopener';
    a.style.display = 'none';
    document.body.appendChild(a);
    a.click();
    a.remove();
    // Revoke after a tick so the navigation/download has a chance to start.
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  /** True when the browser can share files via the Web Share API (level 2). */
  canShare(): boolean {
    return typeof navigator.canShare === 'function' && typeof navigator.share === 'function';
  }

  /**
   * Share a single file. Falls back to `download` when sharing is unavailable, unsupported
   * for the given file, or the share is cancelled/fails (other than a user abort, which is
   * silently swallowed).
   */
  async share(blob: Blob, filename: string, mimeType: string): Promise<void> {
    const file = new File([blob], filename, { type: mimeType });
    const data: ShareData = { files: [file], title: filename };

    if (!this.canShare() || !navigator.canShare(data)) {
      this.download(blob, filename);
      return;
    }

    try {
      await navigator.share(data);
    } catch (err) {
      // Treat an explicit user cancellation as a no-op; otherwise fall back to download.
      if (err instanceof DOMException && err.name === 'AbortError') return;
      this.download(blob, filename);
    }
  }
}
