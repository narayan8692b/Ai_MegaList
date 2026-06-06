/** Friendly empty-state placeholder with optional icon + action. */
import type { ReactNode } from 'react';

interface EmptyStateProps {
  title: string;
  message?: string;
  icon?: ReactNode;
  action?: ReactNode;
}

export function EmptyState({ title, message, icon, action }: EmptyStateProps) {
  return (
    <div className="empty-state">
      {icon && <div aria-hidden="true">{icon}</div>}
      <h3>{title}</h3>
      {message && <p className="text-muted">{message}</p>}
      {action}
    </div>
  );
}
