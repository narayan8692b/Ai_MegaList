/**
 * Documents within a single folder. Reuses the library list presentation (DocumentCard
 * grid) with favorite + delete actions scoped to the folder.
 */
import { useCallback, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useServices } from '@/app/ServicesProvider';
import { useAsync } from '@/ui/hooks/useAsync';
import type { Document, Folder } from '@/domain/models';
import { DocumentCard } from '@/ui/components/DocumentCard';
import { EmptyState } from '@/ui/components/EmptyState';
import { Spinner } from '@/ui/components/Spinner';
import { ConfirmDialog } from '@/ui/components/ConfirmDialog';
import './library.css';

export function FolderDetailScreen() {
  const { id } = useParams<{ id: string }>();
  const services = useServices();
  const navigate = useNavigate();
  const [reloadKey, setReloadKey] = useState(0);
  const bump = useCallback(() => setReloadKey((k) => k + 1), []);

  const folderState = useAsync<Folder | null>(async () => {
    const all = await services.folders.getAll(null);
    return all.find((f) => f.id === id) ?? null;
  }, [services, id, reloadKey]);

  const docsState = useAsync<Document[]>(
    () => services.documents.getAll(id ?? null),
    [services, id, reloadKey],
  );

  const [deleteDoc, setDeleteDoc] = useState<Document | null>(null);

  const toggleFavorite = useCallback(
    async (doc: Document) => {
      await services.documents.setFavorite(doc.id, !doc.isFavorite);
      bump();
    },
    [services, bump],
  );

  const confirmDelete = useCallback(async () => {
    if (!deleteDoc) return;
    await services.documents.delete(deleteDoc.id);
    setDeleteDoc(null);
    bump();
  }, [deleteDoc, services, bump]);

  const documents = docsState.value ?? [];
  const loading = docsState.loading && !docsState.value;

  return (
    <div className="library stack">
      <header className="library__head">
        <button className="btn btn--text" onClick={() => navigate('/documents')} aria-label="Back">
          ‹ Documents
        </button>
      </header>
      <h1>{folderState.value?.name ?? 'Folder'}</h1>

      {loading ? (
        <Spinner fill />
      ) : documents.length === 0 ? (
        <EmptyState
          title="Empty folder"
          message="Move documents here from their action menu."
        />
      ) : (
        <div className="doc-grid">
          {documents.map((doc) => (
            <DocumentCard
              key={doc.id}
              doc={doc}
              onToggleFavorite={toggleFavorite}
              onMenu={(d) => setDeleteDoc(d)}
            />
          ))}
        </div>
      )}

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
