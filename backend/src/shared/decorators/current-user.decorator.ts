import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';
import { AccessTokenPayload } from '../../modules/auth/infrastructure/services/jwt.service';

export interface AuthenticatedRequest extends Request {
  user: AccessTokenPayload;
}

/** Reads the payload JwtAuthGuard attached to the request after verifying the access token. */
export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AccessTokenPayload => {
    const request = ctx.switchToHttp().getRequest<AuthenticatedRequest>();
    return request.user;
  },
);
