/**
 * Shows the perspective-corrected image large, with a horizontal strip of filter
 * thumbnails (FilterStrip). Selecting a filter re-applies it to the corrected blob for the
 * big preview. "Add page" commits the active page and returns to capture; "Save" finalizes
 * the whole session: applies filters, runs OCR (with progress), stores blobs, builds the
 * Document, persists it and navigates to its detail screen.
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useServices } from '@/app/ServicesProvider';
import { useScanSession } from '@/ui/scan/ScanSessionProvider';
import {
  ScanFilter,
  SyncStatus,
  type Document,
  type Page,
  type ScanPage,
} from '@/domain/models';
import { FilterStrip } from '@/ui/components/FilterStrip';
import { Spinner } from '@/ui/components/Spinner';
import './filter.css';

export function FilterScreen() {
  const services = useServices();
  const navigate = useNavigate();
  const session = useScanSession();
  const { active, correctedBlob, filter, setFilter, pages, commitActivePage, title, setTitle, reset } =
    session;

  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [previewLoading, setPreviewLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [progress, setProgress] = useState<{ done: number; total: number } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const urlRef = useRef<string | null>(null);

  // Bounce back if we somehow have no corrected image.
  useEffect(() => {
    if (!active || !correctedBlob) navigate('/scan', { replace: true });
  }, [active, correctedBlob, navigate]);

  // Recompute the big preview when the selected filter (or corrected blob) changes.
  useEffect(() => {
    if (!correctedBlob) return;
    let cancelled = false;
    setPreviewLoading(true);

    async function build() {
      try {
        const out =
          filter === ScanFilter.ORIGINAL
            ? correctedBlob!
            : await services.imageProcessor.applyFilter(correctedBlob!, filter);
        if (cancelled) return;
        const url = URL.createObjectURL(out);
        if (urlRef.current) URL.revokeObjectURL(urlRef.current);
        urlRef.current = url;
        setPreviewUrl(url);
      } catch {
        if (!cancelled) setError('Could not render the preview.');
      } finally {
        if (!cancelled) setPreviewLoading(false);
      }
    }
    void build();

    return () => {
      cancelled = true;
    };
  }, [correctedBlob, filter, services]);

  // Revoke the preview URL on unmount.
  useEffect(() => {
    return () => {
      if (urlRef.current) URL.revokeObjectURL(urlRef.current);
      urlRef.current = null;
    };
  }, []);

  const handleAddPage = useCallback(() => {
    commitActivePage();
    navigate('/scan');
  }, [commitActivePage, navigate]);

  // Render the processed blob for a ScanPage (reuse its blob if filter matches & already done).
  const processPage = useCallback(
    async (page: ScanPage): Promise<Blob> => {
      const base = page.processedBlob;
      if (!base) {
        // No corrected blob yet — fall back to perspective-correcting the original.
        const corrected = await services.imageProcessor.perspectiveCorrect(
          page.original.blob,
          page.corners,
        );
        return page.filter === ScanFilter.ORIGINAL
          ? corrected
          : services.imageProcessor.applyFilter(corrected, page.filter);
      }
      return page.filter === ScanFilter.ORIGINAL
        ? base
        : services.imageProcessor.applyFilter(base, page.filter);
    },
    [services],
  );

  const handleSave = useCallback(async () => {
    if (saving) return;
    setSaving(true);
    setError(null);

    // Build the final list of pages: committed ones + the active (current) page.
    const allScanPages: ScanPage[] = [...pages];
    if (active && correctedBlob) {
      allScanPages.push({
        id: active.id,
        original: active,
        corners: session.corners,
        filter,
        processedBlob: correctedBlob,
        ocrText: '',
      });
    }

    if (allScanPages.length === 0) {
      setError('Nothing to save.');
      setSaving(false);
      return;
    }

    try {
      const docId = services.ids.newId();
      const now = Date.now();
      const pageModels: Page[] = [];
      const ocrTexts: string[] = [];
      setProgress({ done: 0, total: allScanPages.length });

      for (let i = 0; i < allScanPages.length; i++) {
        const sp = allScanPages[i];
        const processed = await processPage(sp);

        // OCR (best-effort: never block saving on a recognition failure).
        let text = '';
        try {
          const result = await services.ocr.recognize(processed);
          text = result.fullText ?? '';
        } catch {
          text = '';
        }
        ocrTexts.push(text);

        const dims = await services.imageProcessor
          .dimensions(processed)
          .catch(() => ({ width: sp.original.width, height: sp.original.height }));

        const originalBlobId = services.ids.newId();
        const processedBlobId = services.ids.newId();
        await services.documents.putBlob(originalBlobId, sp.original.blob);
        await services.documents.putBlob(processedBlobId, processed);

        pageModels.push({
          id: sp.id || services.ids.newId(),
          documentId: docId,
          orderIndex: i,
          originalBlobId,
          processedBlobId,
          corners: sp.corners,
          filter: sp.filter,
          ocrText: text,
          width: dims.width,
          height: dims.height,
        });

        setProgress({ done: i + 1, total: allScanPages.length });
      }

      const doc: Document = {
        id: docId,
        title: title.trim() || 'Untitled',
        pages: pageModels,
        folderId: null,
        tags: [],
        ocrText: ocrTexts.join('\n\n').trim(),
        createdAt: now,
        updatedAt: now,
        isFavorite: false,
        isLocked: false,
        syncStatus: SyncStatus.LOCAL_ONLY,
      };

      await services.documents.upsert(doc);
      reset();
      navigate(`/documents/${docId}`, { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Saving failed.');
      setSaving(false);
      setProgress(null);
    }
  }, [
    saving,
    pages,
    active,
    correctedBlob,
    session.corners,
    filter,
    services,
    processPage,
    title,
    reset,
    navigate,
  ]);

  const totalPages = pages.length + (active ? 1 : 0);

  return (
    <div className="filter-screen">
      <header className="filter-screen__top">
        <button className="filter-screen__topbtn" onClick={() => navigate(-1)} aria-label="Back">
          ‹ Back
        </button>
        <span className="filter-screen__count">
          Page {totalPages} {totalPages === 1 ? '' : `(${totalPages} total)`}
        </span>
        <span className="filter-screen__spacer" />
      </header>

      <div className="filter-screen__preview">
        {previewUrl ? (
          <img src={previewUrl} alt="Filtered page preview" className="filter-screen__img" />
        ) : (
          <Spinner label="Rendering…" />
        )}
        {previewLoading && previewUrl && (
          <div className="filter-screen__preview-busy" aria-hidden="true">
            <span className="spinner" />
          </div>
        )}
      </div>

      <div className="filter-screen__strip">
        <FilterStrip sourceBlob={correctedBlob} selected={filter} onSelect={setFilter} />
      </div>

      <div className="filter-screen__title-field">
        <input
          className="input"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Document title"
          aria-label="Document title"
          disabled={saving}
        />
      </div>

      {error && <p className="filter-screen__error">{error}</p>}

      <footer className="filter-screen__actions">
        <button className="btn btn--tonal" onClick={handleAddPage} disabled={saving}>
          + Add page
        </button>
        <button className="btn btn--filled filter-screen__save" onClick={handleSave} disabled={saving}>
          {saving
            ? progress
              ? `Saving ${progress.done}/${progress.total}…`
              : 'Saving…'
            : `Save${totalPages > 1 ? ` (${totalPages})` : ''}`}
        </button>
      </footer>
    </div>
  );
}
