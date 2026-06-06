/**
 * Run an async function and track loading / error / value state. Re-runs whenever the
 * dependency list changes. Ignores results from stale invocations (avoids race conditions).
 */
import { useCallback, useEffect, useRef, useState } from 'react';

export interface AsyncState<T> {
  value: T | undefined;
  loading: boolean;
  error: unknown;
  /** Manually re-run the async function. */
  reload: () => void;
}

export function useAsync<T>(
  fn: () => Promise<T>,
  deps: ReadonlyArray<unknown>,
): AsyncState<T> {
  const [value, setValue] = useState<T | undefined>(undefined);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>(null);
  const [nonce, setNonce] = useState(0);
  const latest = useRef(0);

  const reload = useCallback(() => setNonce((n) => n + 1), []);

  useEffect(() => {
    const ticket = ++latest.current;
    setLoading(true);
    setError(null);
    fn()
      .then((result) => {
        if (ticket === latest.current) {
          setValue(result);
          setLoading(false);
        }
      })
      .catch((err) => {
        if (ticket === latest.current) {
          setError(err);
          setLoading(false);
        }
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, nonce]);

  return { value, loading, error, reload };
}
