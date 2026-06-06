/** Load documents (optionally scoped to a folder) with loading/error/refresh. */
import { useServices } from '@/app/ServicesProvider';
import type { Document } from '@/domain/models';
import { useAsync } from './useAsync';

export function useDocuments(folderId?: string | null) {
  const services = useServices();
  const state = useAsync<Document[]>(
    () => services.documents.getAll(folderId ?? undefined),
    [folderId],
  );
  return {
    documents: state.value ?? [],
    loading: state.loading,
    error: state.error,
    refresh: state.reload,
  };
}
