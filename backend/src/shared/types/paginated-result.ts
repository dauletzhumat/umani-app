/**
 * Returned as-is by list use-cases/controllers (docs/08_API.md §3's list
 * envelope: { data: [...], meta: {...} }) — ResponseInterceptor detects
 * this shape and passes it through instead of wrapping it under another
 * `data` key.
 */
export interface PaginatedResult<T> {
  data: T[];
  meta: {
    nextCursor: string | null;
    hasMore: boolean;
    limit: number;
  };
}

export function isPaginatedResult(
  value: unknown,
): value is PaginatedResult<unknown> {
  return (
    typeof value === 'object' &&
    value !== null &&
    Array.isArray((value as PaginatedResult<unknown>).data) &&
    typeof (value as PaginatedResult<unknown>).meta === 'object'
  );
}
