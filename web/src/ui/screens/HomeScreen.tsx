/**
 * Landing screen: greeting, quick actions (New Scan / Import), a search box that routes to
 * /search, recent documents (newest first) and favorites.
 */
import { useCallback, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useServices } from '@/app/ServicesProvider';
import { useDocuments } from '@/ui/hooks/useDocuments';
import { DocumentCard } from '@/ui/components/DocumentCard';
import { EmptyState } from '@/ui/components/EmptyState';
import { Spinner } from '@/ui/components/Spinner';
import './home.css';

function greeting(): string {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

export function HomeScreen() {
  const services = useServices();
  const navigate = useNavigate();
  const { documents, loading, refresh } = useDocuments();
  const [query, setQuery] = useState('');

  const recent = useMemo(
    () => [...documents].sort((a, b) => b.updatedAt - a.updatedAt).slice(0, 6),
    [documents],
  );
  const favorites = useMemo(() => documents.filter((d) => d.isFavorite).slice(0, 6), [documents]);

  const submitSearch = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      navigate(query.trim() ? `/search?q=${encodeURIComponent(query.trim())}` : '/search');
    },
    [navigate, query],
  );

  // Import opens the scan flow, where the gallery picker + session are owned.
  const onImport = useCallback(() => navigate('/scan'), [navigate]);

  const toggleFavorite = useCallback(
    async (id: string, next: boolean) => {
      await services.documents.setFavorite(id, next);
      refresh();
    },
    [services, refresh],
  );

  return (
    <div className="home stack">
      <header className="home__header">
        <p className="text-muted">{greeting()}</p>
        <h1>DocScanner</h1>
      </header>

      <form className="home__search" onSubmit={submitSearch} role="search">
        <span className="home__search-icon" aria-hidden="true">🔍</span>
        <input
          className="input home__search-input"
          type="search"
          placeholder="Search documents…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          aria-label="Search documents"
        />
      </form>

      <div className="home__actions">
        <button className="home__action home__action--primary" onClick={() => navigate('/scan')}>
          <span className="home__action-icon" aria-hidden="true">📷</span>
          <span>New Scan</span>
        </button>
        <button className="home__action" onClick={onImport}>
          <span className="home__action-icon" aria-hidden="true">🖼️</span>
          <span>Import</span>
        </button>
      </div>

      {loading ? (
        <Spinner fill />
      ) : (
        <>
          <section className="home__section">
            <div className="home__section-head">
              <h2>Recent</h2>
              {documents.length > 0 && (
                <button className="btn btn--text" onClick={() => navigate('/documents')}>
                  See all
                </button>
              )}
            </div>
            {recent.length === 0 ? (
              <EmptyState
                title="No documents yet"
                message="Tap New Scan to capture your first document."
                action={
                  <button className="btn btn--filled" onClick={() => navigate('/scan')}>
                    New Scan
                  </button>
                }
              />
            ) : (
              <div className="doc-grid">
                {recent.map((doc) => (
                  <DocumentCard
                    key={doc.id}
                    doc={doc}
                    onToggleFavorite={(d) => toggleFavorite(d.id, !d.isFavorite)}
                  />
                ))}
              </div>
            )}
          </section>

          {favorites.length > 0 && (
            <section className="home__section">
              <div className="home__section-head">
                <h2>Favorites</h2>
              </div>
              <div className="doc-grid">
                {favorites.map((doc) => (
                  <DocumentCard
                    key={doc.id}
                    doc={doc}
                    onToggleFavorite={(d) => toggleFavorite(d.id, !d.isFavorite)}
                  />
                ))}
              </div>
            </section>
          )}
        </>
      )}
    </div>
  );
}
