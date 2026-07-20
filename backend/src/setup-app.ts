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
