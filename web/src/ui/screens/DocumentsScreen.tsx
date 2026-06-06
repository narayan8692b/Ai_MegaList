/**
 * Library: a responsive grid of folders + documents, a debounced search bar, create-folder
 * action, tag filter and per-document actions (favorite, delete, move to folder) via a
 * bottom-sheet menu.
 */
import { useCallback, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useServices } from '@/app/ServicesProvider';
import { useAsync } from '@/ui/hooks/useAsync';
import { useDebouncedValue } from '@/ui/hooks/useDebouncedValue';
import type { Document, Folder, Tag } from '@/domain/models';
import { DocumentCard } from '@/ui/components/DocumentCard';
import { EmptyState } from '@/ui/components/EmptyState';
import { Spinner } from '@/ui/components/Spinner';
import { Sheet } from '@/ui/components/Sheet';
import { ConfirmDialog } from '@/ui/components/ConfirmDialog';
import './library.css';

export function DocumentsScreen() {
  const services = useServices();
  const navigate = useNavigate();

  const [rawQuery, setRawQuery] = useState('');
  const query = useDebouncedValue(rawQuery, 300);
  const [activeTag, setActiveTag] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);
  const bump = useCallback(() => setReloadKey((k) => k + 1), []);

  const foldersState = useAsync<Folder[]>(() => services.folders.getAll(null), [services, reloadKey]);
  const tagsState = useAsync<Tag[]>(() => services.folders.getTags(), [services, reloadKey]);
  const docsState = useAsync<Document[]>(
    () => (query.trim() ? services.documents.search(query.trim()) : services.documents.getAll(null)),
    [services, query, reloadKey],
  );

  const folders = foldersState.value ?? [];
  const tags = tagsState.value ?? [];
  const documents = useMemo(() => {
    const list = docsState.value ?? [];
    if (!activeTag) return list;
    return list.filter((d) => d.tags.some((t) => t.id === activeTag));
  }, [docsState.value, activeTag]);

  // Per-document action sheet.
  const [menuDoc, setMenuDoc] = useState<Document | null>(null);
  const [moveDoc, setMoveDoc] = useState<Document | null>(null);
  const [deleteDoc, setDeleteDoc] = useState<Document | null>(null);

  // Create-folder dialog.
  const [folderOpen, setFolderOpen] = useState(false);
  const [folderName, setFolderName] = useState('');

  const toggleFavorite = useCallback(
    async (doc: Document) => {
      await services.documents.setFavorite(doc.id, !doc.isFavorite);
      bump();
    },
    [services, bump],
  );

  const createFolder = useCallback(async () => {
    const name = folderName.trim();
    if (!name) return;
    await services.folders.create({
      id: services.ids.newId(),
      name,
      parentId: null,
      createdAt: Date.now(),
    });
    setFolderName('');
    setFolderOpen(false);
    bump();
  }, [folderName, services, bump]);

  const confirmDelete = useCallback(async () => {
    if (!deleteDoc) return;
    await services.documents.delete(deleteDoc.id);
    setDeleteDoc(null);
    bump();
  }, [deleteDoc, services, bump]);

  const moveTo = useCallback(
    async (folderId: string | null) => {
      if (!moveDoc) return;
      await services.documents.moveToFolder(moveDoc.id, folderId);
      setMoveDoc(null);
      bump();
    },
    [moveDoc, services, bump],
  );

  const loading = docsState.loading && !docsState.value;

  return (
    <div className="library stack">
      <header className="library__head">
        <h1>Documents</h1>
        <button className="btn btn--tonal" onClick={() => setFolderOpen(true)}>
          + Folder
        </button>
      </header>

      <div className="library__search" role="search">
        <span aria-hidden="true">🔍</span>
        <input
          className="input"
          type="search"
          placeholder="Search documents…"
          value={rawQuery}
          onChange={(e) => setRawQuery(e.target.value)}
          aria-label="Search documents"
        />
      </div>

      {tags.length > 0 && (
        <div className="library__tags" role="listbox" aria-label="Filter by tag">
          <button
            className={`chip${activeTag === null ? ' is-active' : ''}`}
            onClick={() => setActiveTag(null)}
            role="option"
            aria-selected={activeTag === null}
          >
            All
          </button>
          {tags.map((t) => (
            <button
              key={t.id}
              className={`chip${activeTag === t.id ? ' is-active' : ''}`}
              onClick={() => setActiveTag((cur) => (cur === t.id ? null : t.id))}
              role="option"
              aria-selected={activeTag === t.id}
            >
              {t.name}
            </button>
          ))}
        </div>
      )}

      {!query && folders.length > 0 && (
        <section className="library__section">
          <h2>Folders</h2>
          <div className="folder-grid">
            {folders.map((f) => (
              <Link key={f.id} to={`/folders/${f.id}`} className="folder-card card card--interactive">
                <span className="folder-card__icon" aria-hidden="true">📁</span>
                <span className="folder-card__name">{f.name}</span>
                {typeof f.documentCount === 'number' && (
                  <span className="folder-card__count text-muted">{f.documentCount}</span>
                )}
              </Link>
            ))}
          </div>
        </section>
      )}

      <section className="library__section">
        {loading ? (
          <Spinner fill />
        ) : documents.length === 0 ? (
          <EmptyState
            title={query ? 'No matches' : 'No documents'}
            message={
              query ? 'Try a different search term.' : 'Scanned documents will appear here.'
            }
            action={
              !query && (
                <button className="btn btn--filled" onClick={() => navigate('/scan')}>
                  New Scan
                </button>
              )
            }
          />
        ) : (
          <div className="doc-grid">
            {documents.map((doc) => (
              <DocumentCard
                key={doc.id}
                doc={doc}
                onToggleFavorite={toggleFavorite}
                onMenu={setMenuDoc}
              />
            ))}
          </div>
        )}
      </section>

      {/* Per-document action sheet */}
      <Sheet open={!!menuDoc} onClose={() => setMenuDoc(null)} title={menuDoc?.title || 'Document'}>
        <div className="sheet-menu">
          <button
            className="sheet-menu__item"
            onClick={() => {
              if (menuDoc) navigate(`/documents/${menuDoc.id}`);
              setMenuDoc(null);
            }}
          >
            Open
          </button>
          <button
            className="sheet-menu__item"
            onClick={() => {
              if (menuDoc) void toggleFavorite(menuDoc);
              setMenuDoc(null);
            }}
          >
            {menuDoc?.isFavorite ? 'Remove favorite' : 'Add to favorites'}
          </button>
          <button
            className="sheet-menu__item"
            onClick={() => {
              setMoveDoc(menuDoc);
              setMenuDoc(null);
            }}
          >
            Move to folder…
          </button>
          <button
            className="sheet-menu__item sheet-menu__item--danger"
            onClick={() => {
              setDeleteDoc(menuDoc);
              setMenuDoc(null);
            }}
          >
            Delete
          </button>
        </div>
      </Sheet>

      {/* Move-to-folder sheet */}
      <Sheet open={!!moveDoc} onClose={() => setMoveDoc(null)} title="Move to folder">
        <div className="sheet-menu">
          <button className="sheet-menu__item" onClick={() => void moveTo(null)}>
            No folder (Library)
          </button>
          {folders.map((f) => (
            <button key={f.id} className="sheet-menu__item" onClick={() => void moveTo(f.id)}>
              📁 {f.name}
            </button>
          ))}
          {folders.length === 0 && <p className="text-muted">No folders yet.</p>}
        </div>
      </Sheet>

      {/* Create-folder sheet */}
      <Sheet
        open={folderOpen}
        onClose={() => setFolderOpen(false)}
        title="New folder"
        footer={
          <>
            <button className="btn btn--text" onClick={() => setFolderOpen(false)}>
              Cancel
            </button>
            <button className="btn btn--filled" onClick={createFolder} disabled={!folderName.trim()}>
              Create
            </button>
          </>
        }
      >
        <input
          className="input"
          placeholder="Folder name"
          value={folderName}
          onChange={(e) => setFolderName(e.target.value)}
          autoFocus
        />
      </Sheet>

      <ConfirmDialog
        open={!!deleteDoc}
        title="Delete document?"
        message={`"${deleteDoc?.title || 'Untitled'}" will be permanently removed.`}
        confirmLabel="Delete"
        danger
        onConfirm={confirmDelete}
        onCancel={() => setDeleteDoc(null)}
      />
    </div>
  );
}
