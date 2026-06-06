/**
 * Minimal ambient declarations for jsPDF 2.x. The published `jspdf` package in this
 * project does not ship its `.d.ts` bundle, so we declare just the subset of the API
 * used by `PdfServiceImpl` to retain type-safety without pulling `any`.
 */
declare module 'jspdf' {
  export type Orientation = 'portrait' | 'landscape' | 'p' | 'l';
  /** Page format: a named size ('a4'…) or explicit [width, height] in the chosen unit. */
  export type Format = string | [number, number];

  export interface EncryptionOptions {
    userPassword?: string;
    ownerPassword?: string;
    userPermissions?: string[];
  }

  export interface jsPDFOptions {
    orientation?: Orientation;
    unit?: 'pt' | 'px' | 'in' | 'mm' | 'cm' | 'ex' | 'em' | 'pc';
    format?: Format;
    compress?: boolean;
    encryption?: EncryptionOptions;
  }

  export interface PageSize {
    getWidth(): number;
    getHeight(): number;
    width: number;
    height: number;
  }

  export interface jsPDFInternal {
    pageSize: PageSize;
  }

  export type ImageFormat = 'JPEG' | 'PNG' | 'WEBP';
  export type ImageCompression = 'NONE' | 'FAST' | 'MEDIUM' | 'SLOW';

  export class jsPDF {
    constructor(options?: jsPDFOptions);
    internal: jsPDFInternal;
    addPage(format?: Format, orientation?: Orientation): jsPDF;
    addImage(
      imageData: string | HTMLImageElement | HTMLCanvasElement | Uint8Array | ArrayBuffer,
      format: ImageFormat,
      x: number,
      y: number,
      width: number,
      height: number,
      alias?: string,
      compression?: ImageCompression,
      rotation?: number,
    ): jsPDF;
    output(type: 'blob'): Blob;
    output(type: 'arraybuffer'): ArrayBuffer;
    output(type: 'datauristring' | 'dataurlstring'): string;
    output(type?: string): string;
    save(filename?: string): jsPDF;
  }

  export default jsPDF;
}
