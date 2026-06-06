/**
 * Material-3 bottom navigation bar with four destinations. Uses react-router `NavLink`
 * for active state and inline SVG icons (no icon dependency). Hidden on full-screen
 * flows (the scan capture / corner-adjustment / filter screens).
 */
import { NavLink, useLocation } from 'react-router-dom';
import type { ReactNode } from 'react';

interface NavItem {
  to: string;
  label: string;
  /** `end` makes the match exact (used for the root "/" destination). */
  end?: boolean;
  icon: ReactNode;
}

const STROKE = {
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 2,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
};

const ITEMS: NavItem[] = [
  {
    to: '/',
    label: 'Home',
    end: true,
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path {...STROKE} d="M3 10.5 12 3l9 7.5" />
        <path {...STROKE} d="M5 9.5V20a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9.5" />
        <path {...STROKE} d="M9.5 21v-6h5v6" />
      </svg>
    ),
  },
  {
    to: '/scan',
    label: 'Scan',
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path {...STROKE} d="M3 8V5a2 2 0 0 1 2-2h3M21 8V5a2 2 0 0 0-2-2h-3M3 16v3a2 2 0 0 0 2 2h3M21 16v3a2 2 0 0 1-2 2h-3" />
        <rect {...STROKE} x="7.5" y="8" width="9" height="8" rx="1.5" />
      </svg>
    ),
  },
  {
    to: '/documents',
    label: 'Documents',
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path {...STROKE} d="M6 3h8l4 4v12a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1Z" />
        <path {...STROKE} d="M13 3v5h5" />
        <path {...STROKE} d="M8.5 13h7M8.5 16.5h5" />
      </svg>
    ),
  },
  {
    to: '/settings',
    label: 'Settings',
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <circle {...STROKE} cx="12" cy="12" r="3" />
        <path {...STROKE} d="M19.4 13a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V19a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-2.7-1.1l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0-1.1-2.7H1a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 2.2 5.4l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 2.7-1.1V1a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7H23a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1Z" />
      </svg>
    ),
  },
];

/** Route prefixes that should hide the bottom nav (immersive full-screen flows). */
const FULLSCREEN_PREFIXES = ['/scan'];

function isFullscreenRoute(pathname: string): boolean {
  return FULLSCREEN_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

export function BottomNav() {
  const { pathname } = useLocation();
  if (isFullscreenRoute(pathname)) return null;

  return (
    <nav className="bottom-nav" aria-label="Primary">
      {ITEMS.map((item) => (
        <NavLink
          key={item.to}
          to={item.to}
          end={item.end}
          className={({ isActive }) =>
            `bottom-nav__item${isActive ? ' is-active' : ''}`
          }
        >
          <span className="bottom-nav__icon-wrap">{item.icon}</span>
          <span>{item.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
