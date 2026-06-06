/**
 * Document detail: a paged/swipeable page viewer (rendering processed blobs via object
 * URLs, revoked on change), the OCR text with copy + export, and actions: export PDF
 * (optional password), share/download, export JPG, rename, favorite, lock toggle, tags
 * editor and delete.
 */
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useServices } from '@/app/ServicesProvider';
import { useAsync } from '@/ui/hooks/useAsync';
import type { Document, Tag } from '@/domain/models';
import { Spinner } from '@/ui/components/Spinner';
import { EmptyState } from '@/ui/components/EmptyState';
import { Sheet } from '@/ui/components/Sheet';
import { ConfirmDialog } from '@/ui/components/ConfirmDialog';
import './detail.css';

export function DocumentDetailScreen() {
  const { id } = useParams<{ id: string }>();
  const services = useServices();
  const navigate = useNavigate();

  const [reloadKey, setReloadKey] = useState(0);
  const bump = useCallback(() => setReloadKey((k) => k + 1), []);

  const state = useAsync<Document | null>(
    () => (id ? services.documents.getById(id) : Promise.resolve(null)),
    [services, id, reloadKey],
  );
  const doc = state.value;

  const [pageIndex, setPageIndex] = useState(0);
  const [pageUrls, setPageUrls] = useState<(string | null)[]>([]);
  const urlsRef = useRef<string[]>([]);

  const [toast, setToast] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // Dialog state.
  const [renameOpen, setRenameOpen] = useState(false);
  const [renameValue, setRenameValue] = useState('');
  const [pdfOpen, setPdfOpen] = useState(false);
  const [pdfPassword, setPdfPassword] = useState('');
  const [tagsOpen, setTagsOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);

  // Resolve all page blobs to object URLs; revoke on doc change / unmount.
  useEffect(() => {
    if (!doc) return;
    let active = true;
    urlsRef.current.forEach((u) => URL.revokeObjectURL(u));
    urlsRef.current = [];
    setPageUrls(doc.pages.map(() => null));

    (async () => {
      for (let i = 0; i < doc.pages.length; i++) {
        const blob = await services.documents.getBlob(doc.pages[i].processedBlobId);
        if (!active) return;
        if (blob) {
          const url = URL.createObjectURL(blob);
          urlsRef.current.push(url);
          setPageUrls((prev) => {
            const next = prev.slice();
            next[i] = url;
            return next;
          });
        }
      }
    })();

    return () => {
      active = false;
      urlsRef.current.forEach((u) => URL.revokeObjectURL(u));
      urlsRef.current = [];
    };
  }, [doc, services]);

  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(null), 2400);
    return () => window.clearTimeout(t);
  }, [toast]);

  const allTagsState = useAsync<Tag[]>(() => services.folders.getTags(), [services, tagsOpen]);

  const clampedIndex = doc ? Math.min(pageIndex, Math.max(0, doc.pages.length - 1)) : 0;

  const copyText = useCallback(async () => {
    if (!doc?.ocrText) return;
    try {
      await navigator.clipboard.writeText(doc.ocrText);
      setToast('Text copied');
    } catch {
      setToast('Copy failed');
    }
  }, [doc]);

  const exportText = useCallback(() => {
    if (!doc) return;
    const blob = new Blob([doc.ocrText], { type: 'text/plain' });
    services.share.download(blob, `${doc.title || 'document'}.txt`);
  }, [doc, services]);

  const pageBlobs = useCallback(async (): Promise<Blob[]> => {
    if (!doc) return [];
    const out: Blob[] = [];
    for (const p of doc.pages) {
      const b = await services.documents.getBlob(p.processedBlobId);
      if (b) out.push(b);
    }
    return out;
  }, [doc, services]);

  const exportPdf = useCallback(async () => {
    if (!doc || busy) return;
    setBusy(true);
    setPdfOpen(false);
    try {
      const blobs = await pageBlobs();
      const settings = await services.settings.get();
      const pdf = await services.pdf.generatePdf(
        blobs,
        settings.pdfQuality,
        pdfPassword.trim() || undefined,
      );
      const filename = `${doc.title || 'document'}.pdf`;
      if (services.share.canShare()) {
        await services.share.share(pdf, filename, 'application/pdf');
      } else {
        services.share.download(pdf, filename);
      }
      setToast('PDF exported');
    } catch (err) {
      setToast(err instanceof Error ? err.message : 'PDF export failed');
    } finally {
      setPdfPassword('');
      setBusy(false);
    }
  }, [doc, busy, pageBlobs, services, pdfPassword]);

  const exportJpg = useCallback(async () => {
    if (!doc || busy) return;
    setBusy(true);
    try {
      const page = doc.pages[clampedIndex];
      const blob = await services.documents.getBlob(page.processedBlobId);
      if (!blob) throw new Error('Page image missing');
      const settings = await services.settings.get();
      const jpg = await services.pdf.exportJpg(blob, settings.pdfQuality);
      services.share.download(jpg, `${doc.title || 'document'}-${clampedIndex + 1}.jpg`);
      setToast('JPG exported');
    } catch (err) {
      setToast(err instanceof Error ? err.message : 'JPG export failed');
    } finally {
      setBusy(false);
    }
  }, [doc, busy, clampedIndex, services]);

  const doRename = useCallback(async () => {
    if (!doc) return;
    await services.documents.upsert({ ...doc, title: renameValue.trim() || 'Untitled', updatedAt: Date.now() });
    setRenameOpen(false);
    bump();
  }, [doc, services, renameValue, bump]);

  const toggleFavorite = useCallback(async () => {
    if (!doc) return;
    await services.documents.setFavorite(doc.id, !doc.isFavorite);
    bump();
  }, [doc, services, bump]);

  const toggleLock = useCallback(async () => {
    if (!doc) return;
    await services.documents.setLocked(doc.id, !doc.isLocked);
    bump();
  }, [doc, services, bump]);

  const toggleTag = useCallback(
    async (tagId: string) => {
      if (!doc) return;
      const has = doc.tags.some((t) => t.id === tagId);
      const nextIds = has ? doc.tags.filter((t) => t.id !== tagId).map((t) => t.id) : [...doc.tags.map((t) => t.id), tagId];
      await services.folders.setDocumentTags(doc.id, nextIds);
      bump();
    },
    [doc, services, bump],
  );

  const confirmDelete = useCallback(async () => {
    if (!doc) return;
    await services.documents.delete(doc.id);
    navigate('/documents', { replace: true });
  }, [doc, services, navigate]);

  const currentUrl = pageUrls[clampedIndex] ?? null;

  const header = useMemo(
    () => (
      <header className="detail__top">
        <button className="detail__topbtn" onClick={() => navigate(-1)} aria-label="Back">
          ‹
        </button>
        <button
          className="detail__title"
          onClick={() => {
            if (doc) {
              setRenameValue(doc.title);
              setRenameOpen(true);
            }
          }}
          title="Rename"
        >
          {doc?.title || 'Untitled'}
        </button>
        <button
          className="detail__topbtn"
          onClick={toggleFavorite}
          aria-pressed={doc?.isFavorite}
          aria-label="Toggle favorite"
        >
          {doc?.isFavorite ? '★' : '☆'}
        </button>
      </header>
    ),
    [doc, navigate, toggleFavorite],
  );

  if (state.loading && !doc) return <Spinner fill />;
  if (!doc) {
    return (
      <div className="detail">
        {header}
        <EmptyState title="Document not found" message="It may have been deleted." />
      </div>
    );
  }

  return (
    <div className="detail">
      {header}

      <div className="detail__viewer">
        {currentUrl ? (
          <img src={currentUrl} alt={`Page ${clampedIndex + 1}`} className="detail__page" />
        ) : (
          <Spinner label="Loading page…" />
        )}
        {doc.pages.length > 1 && (
          <>
            <button
              className="detail__nav detail__nav--prev"
              onClick={() => setPageIndex((i) => Math.max(0, i - 1))}
              disabled={clampedIndex === 0}
              aria-label="Previous page"
            >
              ‹
            </button>
            <button
              className="detail__nav detail__nav--next"
              onClick={() => setPageIndex((i) => Math.min(doc.pages.length - 1, i + 1))}
              disabled={clampedIndex === doc.pages.length - 1}
              aria-label="Next page"
            >
              ›
            </button>
            <span className="detail__page-indicator">
              {clampedIndex + 1} / {doc.pages.length}
            </span>
          </>
        )}
      </div>

      <div className="detail__actions">
        <button className="detail__action" onClick={() => setPdfOpen(true)} disabled={busy}>
          <span aria-hidden="true">📄</span> PDF
        </button>
        <button className="detail__action" onClick={exportJpg} disabled={busy}>
          <span aria-hidden="true">🖼️</span> JPG
        </button>
        <button className="detail__action" onClick={() => setTagsOpen(true)}>
          <span aria-hidden="true">🏷️</span> Tags
        </button>
        <button className="detail__action" onClick={toggleLock}>
          <span aria-hidden="true">{doc.isLocked ? '🔒' : '🔓'}</span>
          {doc.isLocked ? 'Locked' : 'Lock'}
        </button>
        <button className="detail__action detail__action--danger" onClick={() => setDeleteOpen(true)}>
          <span aria-hidden="true">🗑️</span> Delete
        </button>
      </div>

      <section className="detail__ocr card">
        <div className="detail__ocr-head">
          <h3>Extracted text</h3>
          <div className="row">
            <button className="btn btn--text" onClick={copyText} disabled={!doc.ocrText}>
              Copy
            </button>
            <button className="btn btn--text" onClick={exportText} disabled={!doc.ocrText}>
              Export .txt
            </button>
          </div>
        </div>
        {doc.ocrText ? (
          <pre className="detail__ocr-text">{doc.ocrText}</pre>
        ) : (
          <p className="text-muted">No text was recognized.</p>
        )}
      </section>

      {/* Rename */}
      <Sheet
        open={renameOpen}
        onClose={() => setRenameOpen(false)}
        title="Rename document"
        footer={
          <>
            <button className="btn btn--text" onClick={() => setRenameOpen(false)}>
              Cancel
            </button>
            <button className="btn btn--filled" onClick={doRename}>
              Save
            </button>
          </>
        }
      >
        <input
          className="input"
          value={renameValue}
          onChange={(e) => setRenameValue(e.target.value)}
          placeholder="Document title"
          autoFocus
        />
      </Sheet>

      {/* PDF export options */}
      <Sheet
        open={pdfOpen}
        onClose={() => setPdfOpen(false)}
        title="Export PDF"
        footer={
          <>
            <button className="btn btn--text" onClick={() => setPdfOpen(false)}>
              Cancel
            </button>
            <button className="btn btn--filled" onClick={exportPdf}>
              Export
            </button>
          </>
        }
      >
        <p className="text-muted">Optionally protect the PDF with a password.</p>
        <input
          className="input"
          type="password"
          value={pdfPassword}
          onChange={(e) => setPdfPassword(e.target.value)}
          placeholder="Password (optional)"
          autoComplete="new-password"
        />
      </Sheet>

      {/* Tags editor */}
      <Sheet open={tagsOpen} onClose={() => setTagsOpen(false)} title="Tags">
        {allTagsState.loading ? (
          <Spinner />
        ) : (allTagsState.value ?? []).length === 0 ? (
          <p className="text-muted">No tags defined yet.</p>
        ) : (
          <div className="library__tags">
            {(allTagsState.value ?? []).map((t) => {
              const on = doc.tags.some((x) => x.id === t.id);
              return (
                <button
                  key={t.id}
                  className={`chip${on ? ' is-active' : ''}`}
                  onClick={() => toggleTag(t.id)}
                >
                  {on ? '✓ ' : ''}
                  {t.name}
                </button>
              );
            })}
          </div>
        )}
      </Sheet>

      <ConfirmDialog
        open={deleteOpen}
        title="Delete document?"
        message="This permanently removes the document and its pages."
        confirmLabel="Delete"
        danger
        onConfirm={confirmDelete}
        onCancel={() => setDeleteOpen(false)}
      />

      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
