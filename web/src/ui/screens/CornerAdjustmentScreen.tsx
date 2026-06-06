/**
 * THE signature screen, shown by default after every capture. The captured image is drawn
 * to a canvas with four draggable corner handles, a connecting quadrilateral and a shaded
 * mask outside it (live crop preview). While dragging, a circular magnifier lens shows a
 * zoomed view under the active handle for precise placement.
 *
 * Corners are kept normalized (0..1) in the session; we map to/from canvas pixels
 * accounting for object-fit: contain letterboxing of the source image.
 */
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useServices } from '@/app/ServicesProvider';
import { useScanSession } from '@/ui/scan/ScanSessionProvider';
import {
  FULL_CORNERS,
  cornersToList,
  cornersFromList,
  type DocumentCorners,
  type PointF,
} from '@/domain/models';
import { Spinner } from '@/ui/components/Spinner';
import './corner-adjust.css';

/** The displayed image rectangle inside the canvas (object-fit: contain). */
interface FitRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

const HANDLE_RADIUS = 14;
const MAG_SIZE = 132;
const MAG_ZOOM = 2.4;

const CORNER_KEYS = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft'] as const;
type CornerKey = (typeof CORNER_KEYS)[number];

function clamp01(v: number): number {
  return Math.min(1, Math.max(0, v));
}

function computeFit(canvasW: number, canvasH: number, imgW: number, imgH: number): FitRect {
  if (imgW === 0 || imgH === 0) return { x: 0, y: 0, width: canvasW, height: canvasH };
  const scale = Math.min(canvasW / imgW, canvasH / imgH);
  const width = imgW * scale;
  const height = imgH * scale;
  return { x: (canvasW - width) / 2, y: (canvasH - height) / 2, width, height };
}

export function CornerAdjustmentScreen() {
  const services = useServices();
  const navigate = useNavigate();
  const { active, corners, setCorners, setCorrectedBlob } = useScanSession();

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const imgRef = useRef<HTMLImageElement | null>(null);
  const fitRef = useRef<FitRect>({ x: 0, y: 0, width: 0, height: 0 });
  const dprRef = useRef(1);

  const [imgReady, setImgReady] = useState(false);
  const [dragging, setDragging] = useState<CornerKey | null>(null);
  const [magnifier, setMagnifier] = useState<{ cx: number; cy: number } | null>(null);
  const [working, setWorking] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // If we arrived without an active capture (e.g. refresh), bounce back to capture.
  useEffect(() => {
    if (!active) navigate('/scan', { replace: true });
  }, [active, navigate]);

  // Load the captured blob into an HTMLImageElement once.
  useEffect(() => {
    if (!active) return;
    let url: string | null = URL.createObjectURL(active.blob);
    const img = new Image();
    img.onload = () => {
      imgRef.current = img;
      setImgReady(true);
    };
    img.onerror = () => setError('Could not load the captured image.');
    img.src = url;
    return () => {
      if (url) URL.revokeObjectURL(url);
      url = null;
      imgRef.current = null;
      setImgReady(false);
    };
  }, [active]);

  // Convert a normalized point to canvas (CSS px) coordinates.
  const toCanvas = useCallback((p: PointF): { x: number; y: number } => {
    const fit = fitRef.current;
    return { x: fit.x + p.x * fit.width, y: fit.y + p.y * fit.height };
  }, []);

  // Convert a canvas (CSS px) point to a normalized point.
  const toNorm = useCallback((x: number, y: number): PointF => {
    const fit = fitRef.current;
    if (fit.width === 0 || fit.height === 0) return { x: 0, y: 0 };
    return {
      x: clamp01((x - fit.x) / fit.width),
      y: clamp01((y - fit.y) / fit.height),
    };
  }, []);

  // Main draw routine: image, mask, quad, handles.
  const draw = useCallback(() => {
    const canvas = canvasRef.current;
    const img = imgRef.current;
    if (!canvas || !img) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const dpr = dprRef.current;
    const cssW = canvas.width / dpr;
    const cssH = canvas.height / dpr;

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, cssW, cssH);

    const fit = computeFit(cssW, cssH, img.naturalWidth, img.naturalHeight);
    fitRef.current = fit;

    // Image.
    ctx.drawImage(img, fit.x, fit.y, fit.width, fit.height);

    const pts = cornersToList(corners).map(toCanvas);

    // Shaded mask outside the quad: fill everything, then punch out the quad.
    ctx.save();
    ctx.beginPath();
    ctx.rect(0, 0, cssW, cssH);
    ctx.moveTo(pts[0].x, pts[0].y);
    for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i].x, pts[i].y);
    ctx.closePath();
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fill('evenodd');
    ctx.restore();

    // Quad outline.
    ctx.beginPath();
    ctx.moveTo(pts[0].x, pts[0].y);
    for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i].x, pts[i].y);
    ctx.closePath();
    ctx.strokeStyle = '#57dbcb';
    ctx.lineWidth = 2;
    ctx.stroke();

    // Edge midpoint guides (subtle dots).
    ctx.fillStyle = 'rgba(87, 219, 203, 0.9)';
    for (let i = 0; i < pts.length; i++) {
      const a = pts[i];
      const b = pts[(i + 1) % pts.length];
      ctx.beginPath();
      ctx.arc((a.x + b.x) / 2, (a.y + b.y) / 2, 3, 0, Math.PI * 2);
      ctx.fill();
    }

    // Corner handles.
    pts.forEach((p, i) => {
      const activeHandle = dragging === CORNER_KEYS[i];
      ctx.beginPath();
      ctx.arc(p.x, p.y, HANDLE_RADIUS, 0, Math.PI * 2);
      ctx.fillStyle = activeHandle ? 'rgba(87, 219, 203, 0.35)' : 'rgba(255,255,255,0.18)';
      ctx.fill();
      ctx.lineWidth = 2.5;
      ctx.strokeStyle = '#ffffff';
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(p.x, p.y, 3.5, 0, Math.PI * 2);
      ctx.fillStyle = '#ffffff';
      ctx.fill();
    });
  }, [corners, dragging, toCanvas]);

  // Size the canvas backing store to its CSS box (with DPR) and redraw.
  const resize = useCallback(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;
    const rect = container.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    dprRef.current = dpr;
    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
    canvas.style.width = `${rect.width}px`;
    canvas.style.height = `${rect.height}px`;
    draw();
  }, [draw]);

  useEffect(() => {
    if (!imgReady) return;
    resize();
    const ro = new ResizeObserver(() => resize());
    if (containerRef.current) ro.observe(containerRef.current);
    window.addEventListener('orientationchange', resize);
    return () => {
      ro.disconnect();
      window.removeEventListener('orientationchange', resize);
    };
  }, [imgReady, resize]);

  // Redraw on any corner / drag change.
  useEffect(() => {
    draw();
  }, [draw]);

  // Pick the nearest handle within grab distance of a canvas point.
  const hitTest = useCallback(
    (x: number, y: number): CornerKey | null => {
      const pts = cornersToList(corners).map(toCanvas);
      let best: CornerKey | null = null;
      let bestDist = HANDLE_RADIUS * 2.2;
      pts.forEach((p, i) => {
        const d = Math.hypot(p.x - x, p.y - y);
        if (d < bestDist) {
          bestDist = d;
          best = CORNER_KEYS[i];
        }
      });
      return best;
    },
    [corners, toCanvas],
  );

  const pointerPos = useCallback((e: React.PointerEvent): { x: number; y: number } => {
    const canvas = canvasRef.current!;
    const rect = canvas.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  }, []);

  const onPointerDown = useCallback(
    (e: React.PointerEvent) => {
      if (!imgReady) return;
      const { x, y } = pointerPos(e);
      const hit = hitTest(x, y);
      if (!hit) return;
      (e.target as Element).setPointerCapture(e.pointerId);
      setDragging(hit);
      setMagnifier({ cx: x, cy: y });
    },
    [imgReady, pointerPos, hitTest],
  );

  const onPointerMove = useCallback(
    (e: React.PointerEvent) => {
      if (!dragging) return;
      const { x, y } = pointerPos(e);
      const norm = toNorm(x, y);
      const list = cornersToList(corners);
      const idx = CORNER_KEYS.indexOf(dragging);
      const next = list.slice();
      next[idx] = norm;
      setCorners(cornersFromList(next));
      setMagnifier({ cx: x, cy: y });
    },
    [dragging, pointerPos, toNorm, corners, setCorners],
  );

  const endDrag = useCallback(() => {
    setDragging(null);
    setMagnifier(null);
  }, []);

  // Magnifier rendering: draw the source region under the active handle, zoomed, + crosshair.
  const magCanvasRef = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    if (!magnifier || !dragging) return;
    const mag = magCanvasRef.current;
    const img = imgRef.current;
    if (!mag || !img) return;
    const mctx = mag.getContext('2d');
    if (!mctx) return;

    const dpr = window.devicePixelRatio || 1;
    if (mag.width !== MAG_SIZE * dpr) {
      mag.width = MAG_SIZE * dpr;
      mag.height = MAG_SIZE * dpr;
    }
    mctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    mctx.clearRect(0, 0, MAG_SIZE, MAG_SIZE);

    const fit = fitRef.current;
    // Active corner position in canvas px → source-image px.
    const idx = CORNER_KEYS.indexOf(dragging);
    const norm = cornersToList(corners)[idx];
    const srcX = norm.x * img.naturalWidth;
    const srcY = norm.y * img.naturalHeight;

    // How much source area maps to the lens, given the on-screen scale and zoom.
    const screenScale = fit.width / img.naturalWidth || 1;
    const srcSpan = MAG_SIZE / (screenScale * MAG_ZOOM);

    mctx.save();
    mctx.beginPath();
    mctx.arc(MAG_SIZE / 2, MAG_SIZE / 2, MAG_SIZE / 2, 0, Math.PI * 2);
    mctx.clip();
    mctx.fillStyle = '#000';
    mctx.fillRect(0, 0, MAG_SIZE, MAG_SIZE);
    mctx.drawImage(
      img,
      srcX - srcSpan / 2,
      srcY - srcSpan / 2,
      srcSpan,
      srcSpan,
      0,
      0,
      MAG_SIZE,
      MAG_SIZE,
    );
    // Crosshair.
    mctx.strokeStyle = 'rgba(87, 219, 203, 0.95)';
    mctx.lineWidth = 1.5;
    mctx.beginPath();
    mctx.moveTo(MAG_SIZE / 2, MAG_SIZE / 2 - 12);
    mctx.lineTo(MAG_SIZE / 2, MAG_SIZE / 2 + 12);
    mctx.moveTo(MAG_SIZE / 2 - 12, MAG_SIZE / 2);
    mctx.lineTo(MAG_SIZE / 2 + 12, MAG_SIZE / 2);
    mctx.stroke();
    mctx.restore();
  }, [magnifier, dragging, corners]);

  // Position the lens away from the finger: opposite horizontal half, near the top.
  const magStyle = useMemo<React.CSSProperties | undefined>(() => {
    if (!magnifier) return undefined;
    const container = containerRef.current;
    const width = container?.clientWidth ?? 0;
    const onRight = magnifier.cx > width / 2;
    return {
      top: 16,
      left: onRight ? 16 : undefined,
      right: onRight ? undefined : 16,
    };
  }, [magnifier]);

  const handleAutoDetect = useCallback(async () => {
    if (!active || working) return;
    setWorking(true);
    setError(null);
    try {
      const detected = await services.imageProcessor.detectEdges(active.blob);
      setCorners(detected);
    } catch {
      setError('Edge detection failed. Adjust the corners manually.');
    } finally {
      setWorking(false);
    }
  }, [active, working, services, setCorners]);

  const handleReset = useCallback(() => {
    setCorners(FULL_CORNERS as DocumentCorners);
  }, [setCorners]);

  const handleConfirm = useCallback(async () => {
    if (!active || working) return;
    setWorking(true);
    setError(null);
    try {
      const corrected = await services.imageProcessor.perspectiveCorrect(active.blob, corners);
      setCorrectedBlob(corrected);
      navigate('/scan/filter');
    } catch {
      setError('Could not apply the crop. Please try again.');
      setWorking(false);
    }
  }, [active, working, services, corners, setCorrectedBlob, navigate]);

  if (!active) return <Spinner fill label="Preparing…" />;

  return (
    <div className="corner-adjust">
      <header className="corner-adjust__top">
        <button
          className="corner-adjust__topbtn"
          onClick={() => navigate(-1)}
          aria-label="Back"
        >
          ‹ Back
        </button>
        <span className="corner-adjust__title">Adjust corners</span>
        <span className="corner-adjust__spacer" />
      </header>

      <div className="corner-adjust__stage" ref={containerRef}>
        {!imgReady && (
          <div className="corner-adjust__loading">
            <Spinner label="Loading image…" />
          </div>
        )}
        <canvas
          ref={canvasRef}
          className="corner-adjust__canvas"
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={endDrag}
          onPointerCancel={endDrag}
          style={{ touchAction: 'none' }}
        />
        {magnifier && dragging && (
          <div className="corner-adjust__magnifier" style={magStyle} aria-hidden="true">
            <canvas
              ref={magCanvasRef}
              style={{ width: MAG_SIZE, height: MAG_SIZE }}
            />
          </div>
        )}
      </div>

      {error && <p className="corner-adjust__error">{error}</p>}

      <div className="corner-adjust__tools">
        <button className="btn btn--text corner-adjust__tool" onClick={handleAutoDetect} disabled={working}>
          <span aria-hidden="true">◳</span> Auto Detect
        </button>
        <button className="btn btn--text corner-adjust__tool" onClick={handleReset} disabled={working}>
          <span aria-hidden="true">⟲</span> Reset
        </button>
      </div>

      <footer className="corner-adjust__actions">
        <button className="btn btn--filled corner-adjust__confirm" onClick={handleConfirm} disabled={working}>
          {working ? 'Processing…' : 'Confirm'}
        </button>
      </footer>
    </div>
  );
}
