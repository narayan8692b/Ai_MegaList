/**
 * A document tile: thumbnail (first page processed blob), title, page count + date, and an
 * optional overflow menu trigger. Used in grids and lists.
 */
import { Link } from 'react-router-dom';
import type { Document } from '@/domain/models';
import { pageCount } from '@/domain/models';
import { BlobImage } from './BlobImage';
import './DocumentCard.css';

interface DocumentCardProps {
  doc: Document;
  onToggleFavorite?: (doc: Document) => void;
  onMenu?: (doc: Document) => void;
}

function formatDate(ts: number): string {
  return new Date(ts).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

export function DocumentCard({ doc, onToggleFavorite, onMenu }: DocumentCardProps) {
  const firstPage = doc.pages[0];
  return (
    <div className="doc-card card card--interactive">
      <Link to={`/documents/${doc.id}`} className="doc-card__thumb-link" aria-label={doc.title}>
        <div className="doc-card__thumb">
          <BlobImage
            blobId={firstPage?.processedBlobId}
            alt=""
            className="doc-card__img"
            loading="lazy"
          />
          {doc.isLocked && (
            <span className="doc-card__badge" title="Locked" aria-hidden="true">
              🔒
            </span>
          )}
          <span className="doc-card__pages">{pageCount(doc)}</span>
        </div>
      </Link>
      <div className="doc-card__meta">
        <div className="doc-card__title-row">
          <Link to={`/documents/${doc.id}`} className="doc-card__title" title={doc.title}>
            {doc.title || 'Untitled'}
          </Link>
          {onToggleFavorite && (
            <button
              className="doc-card__fav"
              aria-pressed={doc.isFavorite}
              aria-label={doc.isFavorite ? 'Remove favorite' : 'Add favorite'}
              onClick={() => onToggleFavorite(doc)}
            >
              {doc.isFavorite ? '★' : '☆'}
            </button>
          )}
        </div>
        <div className="doc-card__sub text-muted">
          <span>{formatDate(doc.updatedAt)}</span>
          {onMenu && (
            <button
              className="doc-card__menu"
              aria-label="More actions"
              onClick={() => onMenu(doc)}
            >
              ⋯
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
