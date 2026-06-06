/**
 * Horizontal strip of filter thumbnails. For each ScanFilter, lazily renders a small
 * preview by applying the filter to `sourceBlob` through the ImageProcessor. The selected
 * filter is highlighted. Object URLs are revoked on cleanup.
 */
import { useEffect, useRef, useState } from 'react';
import { useServices } from '@/app/ServicesProvider';
import { FILTER_LABELS, ScanFilter } from '@/domain/models';
import './FilterStrip.css';

interface FilterStripProps {
  sourceBlob: Blob | null;
  selected: ScanFilter;
  onSelect: (filter: ScanFilter) => void;
}

const ALL_FILTERS = Object.values(ScanFilter) as ScanFilter[];

export function FilterStrip({ sourceBlob, selected, onSelect }: FilterStripProps) {
  const services = useServices();
  const [thumbs, setThumbs] = useState<Partial<Record<ScanFilter, string>>>({});
  const urlsRef = useRef<string[]>([]);

  useEffect(() => {
    let active = true;
    // Reset on new source.
    urlsRef.current.forEach((u) => URL.revokeObjectURL(u));
    urlsRef.current = [];
    setThumbs({});

    if (!sourceBlob) return;

    async function build() {
      // Make a small base thumbnail first so per-filter work stays cheap.
      let base: Blob = sourceBlob!;
      try {
        base = await services.imageProcessor.createThumbnail(sourceBlob!, 160);
      } catch {
        base = sourceBlob!;
      }
      for (const filter of ALL_FILTERS) {
        if (!active) return;
        try {
          const out =
            filter === ScanFilter.ORIGINAL
              ? base
              : await services.imageProcessor.applyFilter(base, filter);
          if (!active) return;
          const url = URL.createObjectURL(out);
          urlsRef.current.push(url);
          setThumbs((prev) => ({ ...prev, [filter]: url }));
        } catch {
          /* skip a failed preview */
        }
      }
    }
    void build();

    return () => {
      active = false;
      urlsRef.current.forEach((u) => URL.revokeObjectURL(u));
      urlsRef.current = [];
    };
  }, [sourceBlob, services]);

  return (
    <div className="filter-strip" role="listbox" aria-label="Filters">
      {ALL_FILTERS.map((filter) => {
        const url = thumbs[filter];
        const isSelected = filter === selected;
        return (
          <button
            key={filter}
            role="option"
            aria-selected={isSelected}
            className={`filter-strip__item${isSelected ? ' is-selected' : ''}`}
            onClick={() => onSelect(filter)}
          >
            <span className="filter-strip__thumb">
              {url ? (
                <img src={url} alt="" />
              ) : (
                <span className="filter-strip__thumb-loading" aria-hidden="true" />
              )}
            </span>
            <span className="filter-strip__label">{FILTER_LABELS[filter]}</span>
          </button>
        );
      })}
    </div>
  );
}
