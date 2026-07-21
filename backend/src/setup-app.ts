import { HttpStatus, INestApplication, ValidationPipe } from '@nestjs/common';
import { ValidationError } from 'class-validator';
import { AppException } from './shared/exceptions/app.exception';
import { HttpExceptionFilter } from './shared/filters/http-exception.filter';
import { ResponseInterceptor } from './shared/interceptors/response.interceptor';

/**
 * Shared between main.ts and e2e tests so the test app is configured
 * identically to the real one (prefix, validation, error/response shape).
 */
export function setupApp(app: INestApplication): void {
  app.setGlobalPrefix('api/v1', { exclude: ['health'] });

  // Mobile clients (native HTTP) never hit this — it's the Flutter *web*
  // build (and any future browser-based client) that needs it, since it
  // runs on its own dev-server origin (e.g. localhost:5050) while the API
  // is on another (localhost:3000). Auth uses a Bearer header, not
  // cookies, so credentials aren't needed. Reflecting any origin is fine
  // for local dev; tighten to an explicit allow-list before any public
  // deployment (T0.5, still deferred).
  app.enableCors({ origin: true });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      exceptionFactory: (errors: ValidationError[]) => {
        const details = errors.flatMap((error) =>
          Object.keys(error.constraints ?? {}).map((issue) => ({
            field: error.property,
            issue,
          })),
        );
        return new AppException(
          HttpStatus.BAD_REQUEST,
          'VALIDATION_ERROR',
          'Validation failed',
          details,
        );
      },
    }),
  );

  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new ResponseInterceptor());
}
