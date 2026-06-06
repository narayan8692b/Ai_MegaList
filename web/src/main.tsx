/**
 * Entry point. Mounts <App /> into #root, loads global styles, and registers the PWA
 * service worker. A tiny banner surfaces the "offline ready" / "update available" states.
 */
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { registerSW } from 'virtual:pwa-register';
import App from './App';
import './styles/global.css';

const container = document.getElementById('root');
if (!container) {
  throw new Error('Root element #root not found');
}

createRoot(container).render(
  <StrictMode>
    <App />
  </StrictMode>,
);

/* ------------------------------- PWA registration ------------------------------- */

/** Minimal, dependency-free banner used for SW lifecycle messages. */
function showBanner(message: string, actionLabel?: string, onAction?: () => void) {
  const existing = document.getElementById('pwa-banner');
  if (existing) existing.remove();

  const banner = document.createElement('div');
  banner.id = 'pwa-banner';
  banner.className = 'toast';
  banner.setAttribute('role', 'status');

  const text = document.createElement('span');
  text.textContent = message;
  banner.appendChild(text);

  if (actionLabel && onAction) {
    const button = document.createElement('button');
    button.className = 'toast__action';
    button.textContent = actionLabel;
    button.addEventListener('click', () => {
      banner.remove();
      onAction();
    });
    banner.appendChild(button);
  }

  document.body.appendChild(banner);

  // Auto-dismiss informational banners (those without an action).
  if (!actionLabel) {
    window.setTimeout(() => banner.remove(), 4000);
  }
}

const updateSW = registerSW({
  immediate: true,
  onNeedRefresh() {
    showBanner('A new version is available.', 'Reload', () => updateSW(true));
  },
  onOfflineReady() {
    showBanner('DocScanner is ready to work offline.');
  },
  onRegisterError(error) {
    console.error('[pwa] Service worker registration failed', error);
  },
});
