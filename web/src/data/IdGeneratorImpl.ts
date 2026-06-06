/** {@link IdGenerator} backed by the Web Crypto UUID generator. */
import type { IdGenerator } from '@/domain/services';

export class IdGeneratorImpl implements IdGenerator {
  newId(): string {
    return crypto.randomUUID();
  }
}
