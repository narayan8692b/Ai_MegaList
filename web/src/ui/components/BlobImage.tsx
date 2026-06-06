/**
 * Renders an <img> from a Blob (passed directly) or a blobId resolved through the
 * DocumentRepository. Creates an object URL and revokes it on unmount / when the source
 * changes, so we never leak URLs.
 */
import { useEffect, useState } from 'react';
import type { ImgHTMLAttributes } from 'react';
import { useServices } from '@/app/ServicesProvider';

type BaseProps = Omit<ImgHTMLAttributes<HTMLImageElement>, 'src'>;

interface BlobImageProps extends BaseProps {
  blob?: Blob | null;
  blobId?: string | null;
  /** Shown while loading or when no image is available. */
  placeholder?: React.ReactNode;
}

export function BlobImage({ blob, blobId, placeholder, alt = '', ...imgProps }: BlobImageProps) {
  const services = useServices();
  const [url, setUrl] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    let created: string | null = null;

    async function resolve() {
      let source: Blob | null | undefined = blob;
      if (!source && blobId) {
        source = await services.documents.getBlob(blobId);
      }
      if (!active) return;
      if (source) {
        created = URL.createObjectURL(source);
        setUrl(created);
      } else {
        setUrl(null);
      }
    }
    void resolve();

    return () => {
      active = false;
      if (created) URL.revokeObjectURL(created);
    };
  }, [blob, blobId, services]);

  if (!url) {
    return <>{placeholder ?? <span className="blob-image__placeholder" aria-hidden="true" />}</>;
  }
  return <img src={url} alt={alt} {...imgProps} />;
}
