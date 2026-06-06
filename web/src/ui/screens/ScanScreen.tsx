/**
 * Full-screen capture. Shows a live camera preview, a shutter button, a gallery-import
 * button and a flip-camera control. On capture/import we begin a scan and route to the
 * corner-adjustment screen. Camera permission failures fall back to gallery import.
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useServices } from '@/app/ServicesProvider';
import { useScanSession } from '@/ui/scan/ScanSessionProvider';
import { Spinner } from '@/ui/components/Spinner';
import './scan.css';

type Facing = 'environment' | 'user';

export function ScanScreen() {
  const services = useServices();
  const navigate = useNavigate();
  const { beginCapture, addPages, pages } = useScanSession();

  const videoRef = useRef<HTMLVideoElement>(null);
  const stopRef = useRef<(() => void) | null>(null);

  const [facing, setFacing] = useState<Facing>('environment');
  const [streaming, setStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // (Re)start the stream whenever the facing mode changes.
  useEffect(() => {
    let cancelled = false;
    const video = videoRef.current;
    if (!video) return;

    setError(null);
    setStreaming(false);

    services.camera
      .startStream(video, facing)
      .then((stop) => {
        if (cancelled) {
          stop();
          return;
        }
        stopRef.current = stop;
        setStreaming(true);
      })
      .catch((err: unknown) => {
        if (cancelled) return;
        setError(
          err instanceof Error
            ? err.message
            : 'Camera unavailable. You can import from your gallery instead.',
        );
      });

    return () => {
      cancelled = true;
      if (stopRef.current) {
        stopRef.current();
        stopRef.current = null;
      }
    };
  }, [services, facing]);

  const handleCapture = useCallback(async () => {
    const video = videoRef.current;
    if (!video || !streaming || busy) return;
    setBusy(true);
    try {
      const captured = await services.camera.capture(video);
      beginCapture(captured);
      navigate('/scan/adjust');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not capture the frame.');
    } finally {
      setBusy(false);
    }
  }, [services, streaming, busy, beginCapture, navigate]);

  const handleImport = useCallback(async () => {
    if (busy) return;
    setBusy(true);
    try {
      const images = await services.camera.pickFromGallery(true);
      if (images.length === 0) return;
      addPages(images);
      navigate('/scan/adjust');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Import failed.');
    } finally {
      setBusy(false);
    }
  }, [services, busy, addPages, navigate]);

  const flip = useCallback(() => {
    setFacing((f) => (f === 'environment' ? 'user' : 'environment'));
  }, []);

  return (
    <div className="scan-capture">
      <div className="scan-capture__stage">
        <video
          ref={videoRef}
          className="scan-capture__video"
          playsInline
          muted
          autoPlay
        />
        {!streaming && !error && (
          <div className="scan-capture__overlay">
            <Spinner label="Starting camera…" />
          </div>
        )}
        {error && (
          <div className="scan-capture__overlay scan-capture__overlay--error">
            <p>{error}</p>
            <button className="btn btn--tonal" onClick={handleImport}>
              Import from gallery
            </button>
          </div>
        )}
        <div className="scan-capture__frame" aria-hidden="true" />
      </div>

      <header className="scan-capture__top">
        <button
          className="scan-capture__topbtn"
          onClick={() => navigate(-1)}
          aria-label="Close scanner"
        >
          ✕
        </button>
        {pages.length > 0 && (
          <span className="scan-capture__count" aria-live="polite">
            {pages.length} page{pages.length === 1 ? '' : 's'}
          </span>
        )}
        <button
          className="scan-capture__topbtn"
          onClick={flip}
          aria-label="Flip camera"
        >
          ⟲
        </button>
      </header>

      <footer className="scan-capture__controls">
        <button
          className="scan-capture__gallery"
          onClick={handleImport}
          disabled={busy}
          aria-label="Import from gallery"
        >
          <svg viewBox="0 0 24 24" width="26" height="26" aria-hidden="true">
            <rect x="3" y="5" width="18" height="14" rx="2" fill="none" stroke="currentColor" strokeWidth="2" />
            <circle cx="8.5" cy="10" r="1.6" fill="currentColor" />
            <path d="M5 17l4-4 3 3 4-5 3 4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
          </svg>
        </button>

        <button
          className="scan-capture__shutter"
          onClick={handleCapture}
          disabled={!streaming || busy}
          aria-label="Capture"
        >
          <span className="scan-capture__shutter-ring" />
        </button>

        <button
          className="scan-capture__flip"
          onClick={flip}
          disabled={busy}
          aria-label="Flip camera"
        >
          <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
            <path d="M4 9a8 8 0 0 1 13-3l2 2M20 15a8 8 0 0 1-13 3l-2-2" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            <path d="M19 4v4h-4M5 20v-4h4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </footer>
    </div>
  );
}
