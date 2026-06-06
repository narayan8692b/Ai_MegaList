/** Simple centered spinner. Reuses the global `.spinner` token. */
interface SpinnerProps {
  label?: string;
  /** Fill a screen-height area (used as a route loading fallback). */
  fill?: boolean;
}

export function Spinner({ label = 'Loading…', fill }: SpinnerProps) {
  const content = (
    <>
      <span className="spinner" aria-hidden="true" />
      <span className="sr-only">{label}</span>
    </>
  );
  if (fill) {
    return (
      <div className="screen-loading" role="status" aria-live="polite">
        {content}
      </div>
    );
  }
  return (
    <span role="status" aria-live="polite">
      {content}
    </span>
  );
}
