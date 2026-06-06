/**
 * Settings: theme mode, PIN lock (+ set-PIN dialog), biometric note, default filter, auto
 * edge detection, PDF quality, cloud-sync placeholder, storage usage and about/version.
 * Persisted through SettingsRepository; theme is also applied via the ThemeProvider.
 */
import { useCallback, useEffect, useState } from 'react';
import { useServices } from '@/app/ServicesProvider';
import { useTheme } from '@/app/theme';
import { useAsync } from '@/ui/hooks/useAsync';
import {
  FILTER_LABELS,
  PdfQuality,
  ScanFilter,
  ThemeMode,
  type AppSettings,
} from '@/domain/models';
import { Spinner } from '@/ui/components/Spinner';
import { Sheet } from '@/ui/components/Sheet';
import './settings.css';

const THEME_OPTIONS: { value: ThemeMode; label: string }[] = [
  { value: ThemeMode.LIGHT, label: 'Light' },
  { value: ThemeMode.DARK, label: 'Dark' },
  { value: ThemeMode.SYSTEM, label: 'System' },
];

const QUALITY_OPTIONS: { value: PdfQuality; label: string }[] = [
  { value: PdfQuality.LOW, label: 'Low' },
  { value: PdfQuality.MEDIUM, label: 'Medium' },
  { value: PdfQuality.HIGH, label: 'High' },
  { value: PdfQuality.ORIGINAL, label: 'Original' },
];

const APP_VERSION = '1.0.0';

function formatBytes(bytes: number): string {
  if (!bytes) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  const i = Math.min(units.length - 1, Math.floor(Math.log(bytes) / Math.log(1024)));
  return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${units[i]}`;
}

export function SettingsScreen() {
  const services = useServices();
  const { mode, setMode } = useTheme();

  const settingsState = useAsync<AppSettings>(() => services.settings.get(), [services]);
  const hasPinState = useAsync<boolean>(() => services.settings.hasPin(), [services]);

  const [settings, setSettings] = useState<AppSettings | null>(null);
  useEffect(() => {
    if (settingsState.value) setSettings(settingsState.value);
  }, [settingsState.value]);

  const [storage, setStorage] = useState<{ usage: number; quota: number } | null>(null);
  useEffect(() => {
    if (navigator.storage?.estimate) {
      navigator.storage
        .estimate()
        .then((e) => setStorage({ usage: e.usage ?? 0, quota: e.quota ?? 0 }))
        .catch(() => setStorage(null));
    }
  }, []);

  const [biometricAvailable, setBiometricAvailable] = useState<boolean | null>(null);
  useEffect(() => {
    const pac = (window as unknown as {
      PublicKeyCredential?: { isUserVerifyingPlatformAuthenticatorAvailable?: () => Promise<boolean> };
    }).PublicKeyCredential;
    if (pac?.isUserVerifyingPlatformAuthenticatorAvailable) {
      pac.isUserVerifyingPlatformAuthenticatorAvailable()
        .then(setBiometricAvailable)
        .catch(() => setBiometricAvailable(false));
    } else {
      setBiometricAvailable(false);
    }
  }, []);

  const patch = useCallback(
    async (p: Partial<AppSettings>) => {
      setSettings((s) => (s ? { ...s, ...p } : s));
      const updated = await services.settings.update(p);
      setSettings(updated);
    },
    [services],
  );

  // Set-PIN dialog.
  const [pinOpen, setPinOpen] = useState(false);
  const [pin, setPin] = useState('');
  const [pin2, setPin2] = useState('');
  const [pinError, setPinError] = useState<string | null>(null);

  const savePin = useCallback(async () => {
    if (pin.length < 4) {
      setPinError('PIN must be at least 4 digits.');
      return;
    }
    if (pin !== pin2) {
      setPinError('PINs do not match.');
      return;
    }
    await services.settings.setPin(pin);
    await patch({ pinLockEnabled: true });
    setPin('');
    setPin2('');
    setPinError(null);
    setPinOpen(false);
    hasPinState.reload();
  }, [pin, pin2, services, patch, hasPinState]);

  const togglePinLock = useCallback(
    async (enabled: boolean) => {
      if (enabled) {
        if (hasPinState.value) {
          await patch({ pinLockEnabled: true });
        } else {
          setPinOpen(true);
        }
      } else {
        await patch({ pinLockEnabled: false });
      }
    },
    [hasPinState.value, patch],
  );

  if (!settings) return <Spinner fill />;

  return (
    <div className="settings stack">
      <h1>Settings</h1>

      <section className="settings__group card">
        <h3>Appearance</h3>
        <div className="settings__seg" role="radiogroup" aria-label="Theme">
          {THEME_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              role="radio"
              aria-checked={mode === opt.value}
              className={`settings__seg-btn${mode === opt.value ? ' is-active' : ''}`}
              onClick={() => void setMode(opt.value)}
            >
              {opt.label}
            </button>
          ))}
        </div>
        <p className="text-muted settings__hint">
          System follows your device's light/dark preference automatically.
        </p>
      </section>

      <section className="settings__group card">
        <h3>Security</h3>
        <label className="settings__row">
          <span>
            PIN lock
            <span className="settings__sub text-muted">
              {hasPinState.value ? 'A PIN is set' : 'Require a PIN to open the app'}
            </span>
          </span>
          <input
            type="checkbox"
            className="settings__switch"
            checked={settings.pinLockEnabled}
            onChange={(e) => void togglePinLock(e.target.checked)}
          />
        </label>
        <button className="btn btn--text settings__inline-btn" onClick={() => setPinOpen(true)}>
          {hasPinState.value ? 'Change PIN' : 'Set PIN'}
        </button>
        <label className="settings__row">
          <span>
            Biometric unlock
            <span className="settings__sub text-muted">
              {biometricAvailable
                ? 'Platform authenticator available (WebAuthn)'
                : 'Not available on this device/browser'}
            </span>
          </span>
          <input
            type="checkbox"
            className="settings__switch"
            checked={settings.biometricLockEnabled}
            disabled={!biometricAvailable}
            onChange={(e) => void patch({ biometricLockEnabled: e.target.checked })}
          />
        </label>
      </section>

      <section className="settings__group card">
        <h3>Scanning</h3>
        <label className="settings__row">
          <span>Default filter</span>
          <select
            className="settings__select"
            value={settings.defaultFilter}
            onChange={(e) => void patch({ defaultFilter: e.target.value as ScanFilter })}
          >
            {Object.values(ScanFilter).map((f) => (
              <option key={f} value={f}>
                {FILTER_LABELS[f]}
              </option>
            ))}
          </select>
        </label>
        <label className="settings__row">
          <span>
            Auto edge detection
            <span className="settings__sub text-muted">Detect document borders after capture</span>
          </span>
          <input
            type="checkbox"
            className="settings__switch"
            checked={settings.autoEdgeDetection}
            onChange={(e) => void patch({ autoEdgeDetection: e.target.checked })}
          />
        </label>
        <label className="settings__row">
          <span>PDF quality</span>
          <select
            className="settings__select"
            value={settings.pdfQuality}
            onChange={(e) => void patch({ pdfQuality: Number(e.target.value) as PdfQuality })}
          >
            {QUALITY_OPTIONS.map((q) => (
              <option key={q.value} value={q.value}>
                {q.label}
              </option>
            ))}
          </select>
        </label>
      </section>

      <section className="settings__group card">
        <h3>Cloud sync</h3>
        <label className="settings__row settings__row--disabled">
          <span>
            Enable cloud sync
            <span className="settings__sub text-muted">
              iCloud isn't available on the web; Google Drive sync requires OAuth setup.
            </span>
          </span>
          <input type="checkbox" className="settings__switch" checked={false} disabled />
        </label>
      </section>

      <section className="settings__group card">
        <h3>Storage</h3>
        {storage ? (
          <>
            <div className="settings__bar" aria-hidden="true">
              <span
                style={{
                  width: storage.quota ? `${Math.min(100, (storage.usage / storage.quota) * 100)}%` : '0%',
                }}
              />
            </div>
            <p className="text-muted">
              {formatBytes(storage.usage)} used
              {storage.quota ? ` of ${formatBytes(storage.quota)} available` : ''}
            </p>
          </>
        ) : (
          <p className="text-muted">Storage estimate unavailable.</p>
        )}
      </section>

      <section className="settings__group card">
        <h3>About</h3>
        <p className="text-muted">DocScanner PWA</p>
        <p className="text-muted">Version {APP_VERSION}</p>
      </section>

      {/* Set / change PIN */}
      <Sheet
        open={pinOpen}
        onClose={() => {
          setPinOpen(false);
          setPin('');
          setPin2('');
          setPinError(null);
        }}
        title={hasPinState.value ? 'Change PIN' : 'Set PIN'}
        footer={
          <>
            <button
              className="btn btn--text"
              onClick={() => {
                setPinOpen(false);
                setPin('');
                setPin2('');
                setPinError(null);
              }}
            >
              Cancel
            </button>
            <button className="btn btn--filled" onClick={savePin}>
              Save
            </button>
          </>
        }
      >
        <div className="stack">
          <input
            className="input lock-gate__pin"
            type="password"
            inputMode="numeric"
            placeholder="Enter PIN"
            value={pin}
            onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
            autoFocus
          />
          <input
            className="input lock-gate__pin"
            type="password"
            inputMode="numeric"
            placeholder="Confirm PIN"
            value={pin2}
            onChange={(e) => setPin2(e.target.value.replace(/\D/g, ''))}
          />
          {pinError && <p className="lock-gate__error">{pinError}</p>}
        </div>
      </Sheet>
    </div>
  );
}
