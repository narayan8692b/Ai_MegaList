/**
 * Application root. Composition order:
 *   ServicesProvider → ThemeProvider → BrowserRouter → LockGate → layout + routes.
 *
 * Screens are code-split with React.lazy so the initial bundle stays small. The screen
 * modules use NAMED exports (per the UI-agent contract), so each lazy import maps the
 * named export onto `default`, which is what React.lazy expects.
 */
import { Suspense, lazy, type ComponentType } from 'react';
import { BrowserRouter, Navigate, Route, Routes, Link } from 'react-router-dom';
import { ServicesProvider } from '@/app/ServicesProvider';
import { ThemeProvider } from '@/app/theme';
import { LockGate } from '@/ui/components/LockGate';
import { BottomNav } from '@/ui/components/BottomNav';
import { ScanSessionProvider } from '@/ui/scan/ScanSessionProvider';

/** Helper: turn a `{ [name]: Component }` module into a `{ default }` for React.lazy. */
function named<T extends ComponentType<unknown>>(
  loader: () => Promise<Record<string, unknown>>,
  exportName: string,
) {
  return lazy(async () => {
    const mod = await loader();
    const Component = mod[exportName] ?? mod.default;
    return { default: Component as T };
  });
}

const HomeScreen = named(() => import('@/ui/screens/HomeScreen'), 'HomeScreen');
const ScanScreen = named(() => import('@/ui/screens/ScanScreen'), 'ScanScreen');
const CornerAdjustmentScreen = named(
  () => import('@/ui/screens/CornerAdjustmentScreen'),
  'CornerAdjustmentScreen',
);
const FilterScreen = named(() => import('@/ui/screens/FilterScreen'), 'FilterScreen');
const DocumentsScreen = named(() => import('@/ui/screens/DocumentsScreen'), 'DocumentsScreen');
const DocumentDetailScreen = named(
  () => import('@/ui/screens/DocumentDetailScreen'),
  'DocumentDetailScreen',
);
const FolderDetailScreen = named(
  () => import('@/ui/screens/FolderDetailScreen'),
  'FolderDetailScreen',
);
const SearchScreen = named(() => import('@/ui/screens/SearchScreen'), 'SearchScreen');
const SettingsScreen = named(() => import('@/ui/screens/SettingsScreen'), 'SettingsScreen');

function ScreenFallback() {
  return (
    <div className="screen-loading" role="status" aria-live="polite">
      <span className="spinner" aria-hidden="true" />
      <span className="sr-only">Loading…</span>
    </div>
  );
}

function NotFound() {
  return (
    <div className="not-found">
      <h2>Page not found</h2>
      <p className="text-muted">We couldn’t find what you were looking for.</p>
      <Link className="btn btn--filled" to="/">
        Go home
      </Link>
    </div>
  );
}

/** Shared layout for the standard (non-immersive) destinations. */
function AppLayout() {
  return (
    <div className="app-layout">
      <main className="app-main">
        <Suspense fallback={<ScreenFallback />}>
          <Routes>
            <Route path="/" element={<HomeScreen />} />
            <Route path="/documents" element={<DocumentsScreen />} />
            <Route path="/documents/:id" element={<DocumentDetailScreen />} />
            <Route path="/folders/:id" element={<FolderDetailScreen />} />
            <Route path="/search" element={<SearchScreen />} />
            <Route path="/settings" element={<SettingsScreen />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Suspense>
      </main>
      <BottomNav />
    </div>
  );
}

/** Immersive full-screen scan flow; wrapped in its (UI-agent-owned) session provider. */
function ScanLayout() {
  return (
    <ScanSessionProvider>
      <div className="app-layout">
        <main className="app-main app-main--fullscreen">
          <Suspense fallback={<ScreenFallback />}>
            <Routes>
              <Route path="/scan" element={<ScanScreen />} />
              <Route path="/scan/adjust" element={<CornerAdjustmentScreen />} />
              <Route path="/scan/filter" element={<FilterScreen />} />
              <Route path="*" element={<Navigate to="/scan" replace />} />
            </Routes>
          </Suspense>
        </main>
      </div>
    </ScanSessionProvider>
  );
}

export default function App() {
  return (
    <ServicesProvider>
      <ThemeProvider>
        <BrowserRouter>
          <LockGate>
            <Routes>
              {/* Immersive scan flow keeps its own provider + layout (no bottom nav). */}
              <Route path="/scan/*" element={<ScanLayout />} />
              {/* Everything else lives in the standard layout with bottom navigation. */}
              <Route path="/*" element={<AppLayout />} />
            </Routes>
          </LockGate>
        </BrowserRouter>
      </ThemeProvider>
    </ServicesProvider>
  );
}
