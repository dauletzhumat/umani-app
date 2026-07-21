import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Request } from 'express';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { isPaginatedResult } from '../types/paginated-result';

/**
 * Wraps successful responses as { data: ... } per docs/08_API.md §3.
 * /health is excluded — it sits outside the versioned API (see the
 * setGlobalPrefix exclude in main.ts) and its contract predates this
 * envelope (T0.1's test expects the bare { status: 'ok' } body).
 *
 * A list use-case may instead return a PaginatedResult ({ data, meta })
 * directly — that shape is passed through unchanged so `meta` lands
 * beside `data` at the top level, not nested inside it (§3's list form).
 */
@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();

    if (request.path === '/health') {
      return next.handle();
    }

    return next
      .handle()
      .pipe(
        map((payload: unknown) =>
          isPaginatedResult(payload) ? payload : { data: payload },
        ),
      );
  }
}
