/**
 * Owns the in-progress scan session shared across the immersive scan flow
 * (`/scan` → `/scan/adjust` → `/scan/filter`). Holds the committed pages plus the
 * "active" capture currently being adjusted/filtered, and exposes the actions the
 * screens use to drive it forward.
 *
 * The shell wraps the `/scan/*` routes with <ScanSessionProvider>, so the state lives
 * for the duration of the scan flow and is torn down when the user leaves it.
 */
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  FULL_CORNERS,
  ScanFilter,
  type CapturedImage,
  type DocumentCorners,
  type ScanPage,
} from '@/domain/models';
import { useServices } from '@/app/ServicesProvider';

interface ScanSessionState {
  /** Title the user will give the document on save. */
  title: string;
  /** Pages already committed in this session. */
  pages: ScanPage[];
  /** The capture currently being adjusted/filtered (null between captures). */
  active: CapturedImage | null;
  /** Working corners for the active capture (normalized 0..1). */
  corners: DocumentCorners;
  /** Filter selected for the active capture. */
  filter: ScanFilter;
  /** Perspective-corrected blob for the active capture (after Confirm). */
  correctedBlob: Blob | null;
}

interface ScanSessionContextValue extends ScanSessionState {
  /** Start adjusting a freshly captured/imported image. */
  beginCapture: (captured: CapturedImage) => void;
  setCorners: (corners: DocumentCorners) => void;
  setFilter: (filter: ScanFilter) => void;
  setCorrectedBlob: (blob: Blob | null) => void;
  /** Promote the active capture to a committed ScanPage and clear the active slot. */
  commitActivePage: () => void;
  /** Queue several captures (gallery import); begins adjusting the first. */
  addPages: (captured: CapturedImage[]) => void;
  setTitle: (title: string) => void;
  /** Clear the whole session (after save or abandon). */
  reset: () => void;
}

const ScanSessionContext = createContext<ScanSessionContextValue | null>(null);

function defaultTitle(): string {
  const now = new Date();
  const stamp = now.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
  return `Scan ${stamp}`;
}

export function ScanSessionProvider({ children }: { children: ReactNode }) {
  const { settings } = useServices();
  const [title, setTitleState] = useState<string>(defaultTitle);
  const [pages, setPages] = useState<ScanPage[]>([]);
  const [queue, setQueue] = useState<CapturedImage[]>([]);
  const [active, setActive] = useState<CapturedImage | null>(null);
  const [corners, setCornersState] = useState<DocumentCorners>(FULL_CORNERS);
  const [filter, setFilterState] = useState<ScanFilter>(ScanFilter.MAGIC_COLOR);
  const [correctedBlob, setCorrectedBlobState] = useState<Blob | null>(null);

  // Pull the user's preferred default filter (best-effort, async).
  useMemo(() => {
    settings
      .get()
      .then((s) => setFilterState(s.defaultFilter))
      .catch(() => {
        /* keep the fallback */
      });
    // settings is stable for the app lifetime.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const beginAdjusting = useCallback((captured: CapturedImage) => {
    setActive(captured);
    setCornersState(captured.detectedCorners ?? FULL_CORNERS);
    setCorrectedBlobState(null);
  }, []);

  const beginCapture = useCallback(
    (captured: CapturedImage) => {
      setQueue([]);
      beginAdjusting(captured);
    },
    [beginAdjusting],
  );

  const addPages = useCallback(
    (captured: CapturedImage[]) => {
      if (captured.length === 0) return;
      const [first, ...rest] = captured;
      setQueue(rest);
      beginAdjusting(first);
    },
    [beginAdjusting],
  );

  const setCorners = useCallback((next: DocumentCorners) => setCornersState(next), []);
  const setFilter = useCallback((next: ScanFilter) => setFilterState(next), []);
  const setCorrectedBlob = useCallback((blob: Blob | null) => setCorrectedBlobState(blob), []);
  const setTitle = useCallback((next: string) => setTitleState(next), []);

  const commitActivePage = useCallback(() => {
    setActive((current) => {
      if (!current) return null;
      const page: ScanPage = {
        id: current.id,
        original: current,
        corners,
        filter,
        processedBlob: correctedBlob ?? undefined,
        ocrText: '',
      };
      setPages((prev) => [...prev, page]);

      // If a gallery queue is pending, immediately start adjusting the next one.
      let nextActive: CapturedImage | null = null;
      setQueue((q) => {
        if (q.length === 0) return q;
        const [head, ...tail] = q;
        nextActive = head;
        return tail;
      });
      if (nextActive) {
        setCornersState((nextActive as CapturedImage).detectedCorners ?? FULL_CORNERS);
        setCorrectedBlobState(null);
        return nextActive;
      }
      return null;
    });
  }, [corners, filter, correctedBlob]);

  const reset = useCallback(() => {
    setTitleState(defaultTitle());
    setPages([]);
    setQueue([]);
    setActive(null);
    setCornersState(FULL_CORNERS);
    setCorrectedBlobState(null);
  }, []);

  const value = useMemo<ScanSessionContextValue>(
    () => ({
      title,
      pages,
      active,
      corners,
      filter,
      correctedBlob,
      beginCapture,
      setCorners,
      setFilter,
      setCorrectedBlob,
      commitActivePage,
      addPages,
      setTitle,
      reset,
    }),
    [
      title,
      pages,
      active,
      corners,
      filter,
      correctedBlob,
      beginCapture,
      setCorners,
      setFilter,
      setCorrectedBlob,
      commitActivePage,
      addPages,
      setTitle,
      reset,
    ],
  );

  return <ScanSessionContext.Provider value={value}>{children}</ScanSessionContext.Provider>;
}

export function useScanSession(): ScanSessionContextValue {
  const ctx = useContext(ScanSessionContext);
  if (!ctx) {
    throw new Error('useScanSession() must be used within a <ScanSessionProvider>');
  }
  return ctx;
}
