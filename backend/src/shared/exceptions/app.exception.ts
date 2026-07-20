import { HttpException, HttpStatus } from '@nestjs/common';

export interface AppExceptionPayload {
  code: string;
  message: string;
  details?: unknown;
}

/**
 * Carries the error `code` from docs/08_API.md §5's catalog, on top of the
 * plain HttpException NestJS gives you — the global filter reads it back
 * out via getResponse() to build the {error: {...}} envelope.
 */
export class AppException extends HttpException {
  constructor(
    status: HttpStatus,
    code: string,
    message: string,
    details?: unknown,
  ) {
    super({ code, message, details }, status);
  }
}
