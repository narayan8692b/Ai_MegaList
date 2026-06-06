/**
 * Full-text search over documents. Debounced query → documents.search. Results show the
 * title plus an OCR snippet with the matched term highlighted; tapping opens the detail.
 */
import { useEffect, useMemo, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { useServices } from '@/app/ServicesProvider';
import { useAsync } from '@/ui/hooks/useAsync';
import { useDebouncedValue } from '@/ui/hooks/useDebouncedValue';
import type { Document } from '@/domain/models';
import { EmptyState } from '@/ui/components/EmptyState';
import { Spinner } from '@/ui/components/Spinner';
import { BlobImage } from '@/ui/components/BlobImage';
import './search.css';

/** Build a snippet around the first match of `term` in `text`, with the match marked. */
function snippet(text: string, term: string): { before: string; match: string; after: string } | null {
  if (!text || !term) return null;
  const idx = text.toLowerCase().indexOf(term.toLowerCase());
  if (idx < 0) return null;
  const start = Math.max(0, idx - 40);
  const end = Math.min(text.length, idx + term.length + 60);
  return {
    before: (start > 0 ? '…' : '') + text.slice(start, idx),
    match: text.slice(idx, idx + term.length),
    after: text.slice(idx + term.length, end) + (end < text.length ? '…' : ''),
  };
}

export function SearchScreen() {
  const services = useServices();
  const [params, setParams] = useSearchParams();
  const [raw, setRaw] = useState(params.get('q') ?? '');
  const query = useDebouncedValue(raw, 300);

  // Keep the URL query string in sync (so back/forward + deep links work).
  useEffect(() => {
    setParams(query.trim() ? { q: query.trim() } : {}, { replace: true });
  }, [query, setParams]);

  const state = useAsync<Document[]>(
    () => (query.trim() ? services.documents.search(query.trim()) : Promise.resolve([])),
    [services, query],
  );

  const results = state.value ?? [];
  const trimmed = query.trim();
  const showLoading = state.loading && !!trimmed;

  const content = useMemo(() => {
    if (!trimmed) {
      return (
        <EmptyState title="Search your documents" message="Find by title or recognized text." />
      );
    }
    if (showLoading) return <Spinner fill />;
    if (results.length === 0) {
      return <EmptyState title="No results" message={`Nothing matched "${trimmed}".`} />;
    }
    return (
      <ul className="search-results stack">
        {results.map((doc) => {
          const snip = snippet(doc.ocrText, trimmed);
          return (
            <li key={doc.id}>
              <Link to={`/documents/${doc.id}`} className="search-result card card--interactive">
                <div className="search-result__thumb">
                  <BlobImage blobId={doc.pages[0]?.processedBlobId} alt="" />
                </div>
                <div className="search-result__body">
                  <span className="search-result__title">{doc.title || 'Untitled'}</span>
                  {snip ? (
                    <span className="search-result__snippet text-muted">
                      {snip.before}
                      <mark>{snip.match}</mark>
                      {snip.after}
                    </span>
                  ) : (
                    <span className="search-result__snippet text-muted">
                      {doc.pages.length} page{doc.pages.length === 1 ? '' : 's'}
                    </span>
                  )}
                </div>
              </Link>
            </li>
          );
        })}
      </ul>
    );
  }, [trimmed, showLoading, results]);

  return (
    <div className="search-screen stack">
      <div className="search-screen__bar" role="search">
        <span aria-hidden="true">🔍</span>
        <input
          className="input"
          type="search"
          placeholder="Search documents…"
          value={raw}
          onChange={(e) => setRaw(e.target.value)}
          aria-label="Search documents"
          autoFocus
        />
      </div>
      {content}
    </div>
  );
}
