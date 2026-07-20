import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Request } from 'express';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/**
 * Wraps successful responses as { data: ... } per docs/08_API.md §3.
 * /health is excluded — it sits outside the versioned API (see the
 * setGlobalPrefix exclude in main.ts) and its contract predates this
 * envelope (T0.1's test expects the bare { status: 'ok' } body).
 */
@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();

    if (request.path === '/health') {
      return next.handle();
    }

    return next.handle().pipe(map((data: unknown) => ({ data })));
  }
}
