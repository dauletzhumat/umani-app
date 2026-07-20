import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { randomUUID } from 'crypto';
import { AppExceptionPayload } from '../exceptions/app.exception';

/**
 * Shapes every 4xx/5xx into docs/08_API.md §3's error envelope:
 * { error: { code, message, details, traceId } }.
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const traceId = randomUUID();

    const { status, code, message, details } = this.resolve(exception);

    this.logger.error(
      `[${traceId}] ${status} ${code}: ${message}`,
      (exception as Error)?.stack,
    );

    response.status(status).json({
      error: { code, message, details, traceId },
    });
  }

  private resolve(exception: unknown): {
    status: number;
    code: string;
    message: string;
    details?: unknown;
  } {
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();

      if (this.isAppExceptionPayload(body)) {
        return {
          status,
          code: body.code,
          message: body.message,
          details: body.details,
        };
      }

      return {
        status,
        code: this.defaultCodeForStatus(status),
        message:
          typeof body === 'string'
            ? body
            : ((body as { message?: string })?.message ?? exception.message),
      };
    }

    return {
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
    };
  }

  private isAppExceptionPayload(body: unknown): body is AppExceptionPayload {
    return (
      typeof body === 'object' &&
      body !== null &&
      'code' in body &&
      'message' in body
    );
  }

  private defaultCodeForStatus(status: number): string {
    const codeByStatus: Record<number, string> = {
      [HttpStatus.BAD_REQUEST]: 'VALIDATION_ERROR',
      [HttpStatus.UNAUTHORIZED]: 'UNAUTHORIZED',
      [HttpStatus.FORBIDDEN]: 'FORBIDDEN_ROLE',
      [HttpStatus.NOT_FOUND]: 'NOT_FOUND',
      [HttpStatus.CONFLICT]: 'CONFLICT',
      [HttpStatus.UNPROCESSABLE_ENTITY]: 'UNPROCESSABLE_BUSINESS_RULE',
      [HttpStatus.TOO_MANY_REQUESTS]: 'RATE_LIMITED',
    };

    return codeByStatus[status] ?? 'INTERNAL_ERROR';
  }
}
