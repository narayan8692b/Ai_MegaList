/**
 * Theme system. Resolves the user's `ThemeMode` (LIGHT / DARK / SYSTEM) from the
 * SettingsRepository, watches `prefers-color-scheme` for SYSTEM, and toggles the
 * `data-theme="dark"` attribute on <html>. Color tokens themselves live in global.css.
 */
import {
  createContext,
  createElement,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { ThemeMode } from '@/domain/models';
import { useServices } from './ServicesProvider';

type ResolvedTheme = 'light' | 'dark';

interface ThemeContextValue {
  /** The user's stored preference. */
  mode: ThemeMode;
  /** The concrete theme currently applied (SYSTEM resolved against the OS). */
  resolved: ResolvedTheme;
  /** Persist a new preference. Updates settings + applies immediately. */
  setMode: (mode: ThemeMode) => Promise<void>;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

const DARK_QUERY = '(prefers-color-scheme: dark)';

function systemPrefersDark(): boolean {
  return typeof window !== 'undefined' && window.matchMedia(DARK_QUERY).matches;
}

function resolveTheme(mode: ThemeMode): ResolvedTheme {
  if (mode === ThemeMode.DARK) return 'dark';
  if (mode === ThemeMode.LIGHT) return 'light';
  return systemPrefersDark() ? 'dark' : 'light';
}

function applyTheme(resolved: ResolvedTheme) {
  const root = document.documentElement;
  if (resolved === 'dark') {
    root.setAttribute('data-theme', 'dark');
  } else {
    root.removeAttribute('data-theme');
  }
  // Keep the browser UI (status bar / address bar) in sync.
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) {
    meta.setAttribute('content', resolved === 'dark' ? '#0B1120' : '#0F766E');
  }
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const { settings } = useServices();
  const [mode, setModeState] = useState<ThemeMode>(ThemeMode.SYSTEM);
  const [resolved, setResolved] = useState<ResolvedTheme>(() => resolveTheme(ThemeMode.SYSTEM));

  // Load the persisted preference once.
  useEffect(() => {
    let cancelled = false;
    settings
      .get()
      .then((s) => {
        if (!cancelled) setModeState(s.themeMode);
      })
      .catch(() => {
        /* fall back to SYSTEM */
      });
    return () => {
      cancelled = true;
    };
  }, [settings]);

  // Apply + react to OS changes when in SYSTEM mode.
  useEffect(() => {
    const next = resolveTheme(mode);
    setResolved(next);
    applyTheme(next);

    if (mode !== ThemeMode.SYSTEM) return;
    const mql = window.matchMedia(DARK_QUERY);
    const onChange = () => {
      const r = resolveTheme(ThemeMode.SYSTEM);
      setResolved(r);
      applyTheme(r);
    };
    mql.addEventListener('change', onChange);
    return () => mql.removeEventListener('change', onChange);
  }, [mode]);

  const setMode = useCallback(
    async (next: ThemeMode) => {
      setModeState(next);
      await settings.update({ themeMode: next });
    },
    [settings],
  );

  const value = useMemo<ThemeContextValue>(
    () => ({ mode, resolved, setMode }),
    [mode, resolved, setMode],
  );

  return createElement(ThemeContext.Provider, { value }, children);
}

export function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) {
    throw new Error('useTheme() must be used within a <ThemeProvider>');
  }
  return ctx;
}
