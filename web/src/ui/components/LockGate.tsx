/**
 * App-wide lock gate. When PIN (or biometric) lock is enabled in settings AND a PIN has
 * actually been set, the whole app is gated behind a PIN prompt until the user unlocks.
 * Once unlocked we remember it in sessionStorage for the lifetime of the tab session, so
 * a reload inside the same tab doesn't re-prompt.
 *
 * The richer dedicated PIN screen is owned by the UI agent; to avoid a hard dependency on
 * an export that may not exist yet, this gate ships a minimal, self-contained inline PIN
 * prompt that talks directly to `SettingsRepository.verifyPin`.
 */
import { useCallback, useEffect, useState, type ReactNode } from 'react';
import { useServices } from '@/app/ServicesProvider';

const SESSION_KEY = 'docscanner.unlocked';

function sessionUnlocked(): boolean {
  try {
    return sessionStorage.getItem(SESSION_KEY) === '1';
  } catch {
    return false;
  }
}

function markUnlocked() {
  try {
    sessionStorage.setItem(SESSION_KEY, '1');
  } catch {
    /* ignore storage errors (private mode etc.) */
  }
}

type GateState =
  | { status: 'checking' }
  | { status: 'locked' }
  | { status: 'unlocked' };

export function LockGate({ children }: { children: ReactNode }) {
  const { settings } = useServices();
  const [state, setState] = useState<GateState>(() =>
    sessionUnlocked() ? { status: 'unlocked' } : { status: 'checking' },
  );

  useEffect(() => {
    if (state.status !== 'checking') return;
    let cancelled = false;
    (async () => {
      try {
        const s = await settings.get();
        const lockEnabled = s.pinLockEnabled || s.biometricLockEnabled;
        const hasPin = lockEnabled ? await settings.hasPin() : false;
        if (cancelled) return;
        if (lockEnabled && hasPin) {
          setState({ status: 'locked' });
        } else {
          markUnlocked();
          setState({ status: 'unlocked' });
        }
      } catch {
        // If settings can't be read, fail open rather than locking the user out.
        if (!cancelled) setState({ status: 'unlocked' });
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [settings, state.status]);

  const handleUnlock = useCallback(() => {
    markUnlocked();
    setState({ status: 'unlocked' });
  }, []);

  if (state.status === 'checking') {
    return (
      <div className="screen-loading" role="status" aria-live="polite">
        <span className="spinner" aria-hidden="true" />
      </div>
    );
  }

  if (state.status === 'locked') {
    return <PinPrompt onUnlock={handleUnlock} verifyPin={settings.verifyPin.bind(settings)} />;
  }

  return <>{children}</>;
}

function PinPrompt({
  onUnlock,
  verifyPin,
}: {
  onUnlock: () => void;
  verifyPin: (pin: string) => Promise<boolean>;
}) {
  const [pin, setPin] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      if (busy || pin.length === 0) return;
      setBusy(true);
      setError('');
      try {
        const ok = await verifyPin(pin);
        if (ok) {
          onUnlock();
        } else {
          setError('Incorrect PIN. Try again.');
          setPin('');
        }
      } catch {
        setError('Could not verify PIN.');
      } finally {
        setBusy(false);
      }
    },
    [busy, pin, verifyPin, onUnlock],
  );

  return (
    <div className="lock-gate">
      <div className="lock-gate__icon" aria-hidden="true">
        <svg width="56" height="56" viewBox="0 0 24 24" fill="none">
          <rect
            x="4"
            y="10.5"
            width="16"
            height="10.5"
            rx="2.5"
            stroke="currentColor"
            strokeWidth="1.8"
          />
          <path
            d="M7.5 10.5V7.5a4.5 4.5 0 0 1 9 0v3"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
          />
          <circle cx="12" cy="15.5" r="1.4" fill="currentColor" />
        </svg>
      </div>
      <div>
        <p className="splash__title">DocScanner is locked</p>
        <p className="text-muted">Enter your PIN to continue.</p>
      </div>
      <form className="lock-gate__form" onSubmit={submit}>
        <input
          className="input lock-gate__pin"
          type="password"
          inputMode="numeric"
          autoComplete="off"
          autoFocus
          aria-label="PIN"
          value={pin}
          disabled={busy}
          onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
        />
        <span className="lock-gate__error" role="alert">
          {error}
        </span>
        <button className="btn btn--filled" type="submit" disabled={busy || pin.length === 0}>
          {busy ? 'Checking…' : 'Unlock'}
        </button>
      </form>
    </div>
  );
}
