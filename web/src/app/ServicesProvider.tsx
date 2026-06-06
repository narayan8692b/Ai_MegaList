/**
 * Provides the app-wide `Services` instance (composition root) through React context.
 * Builds the services exactly once on mount and renders a splash until they are ready.
 */
import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react';
import type { Services } from '@/services/container';
import { createServices } from '@/services/container.impl';

const ServicesContext = createContext<Services | null>(null);

type LoadState =
  | { status: 'loading' }
  | { status: 'ready'; services: Services }
  | { status: 'error'; error: unknown };

export function ServicesProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<LoadState>({ status: 'loading' });

  useEffect(() => {
    let cancelled = false;
    createServices()
      .then((services) => {
        if (!cancelled) setState({ status: 'ready', services });
      })
      .catch((error) => {
        if (!cancelled) setState({ status: 'error', error });
      });
    return () => {
      cancelled = true;
    };
  }, []);

  if (state.status === 'loading') {
    return <Splash />;
  }

  if (state.status === 'error') {
    return <Splash error={state.error} />;
  }

  return (
    <ServicesContext.Provider value={state.services}>
      {children}
    </ServicesContext.Provider>
  );
}

export function useServices(): Services {
  const services = useContext(ServicesContext);
  if (!services) {
    throw new Error('useServices() must be used within a <ServicesProvider>');
  }
  return services;
}

function Splash({ error }: { error?: unknown }) {
  return (
    <div className="splash" role="status" aria-live="polite">
      <div className="splash__logo" aria-hidden="true">
        <svg width="72" height="72" viewBox="0 0 48 48" fill="none">
          <rect x="10" y="6" width="28" height="36" rx="4" fill="currentColor" opacity="0.12" />
          <path
            d="M6 12V6h6M42 12V6h-6M6 36v6h6M42 36v6h-6"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path d="M16 18h16M16 24h16M16 30h10" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
        </svg>
      </div>
      {error ? (
        <div className="splash__error">
          <p className="splash__title">Couldn’t start DocScanner</p>
          <p className="splash__detail">
            {error instanceof Error ? error.message : 'An unexpected error occurred.'}
          </p>
        </div>
      ) : (
        <>
          <p className="splash__title">DocScanner</p>
          <span className="spinner" aria-hidden="true" />
        </>
      )}
    </div>
  );
}
