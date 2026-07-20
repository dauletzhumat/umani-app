import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { TokenExpiredError } from 'jsonwebtoken';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { IS_PUBLIC_KEY } from '../../../../shared/decorators/public.decorator';
import { AuthenticatedRequest } from '../../../../shared/decorators/current-user.decorator';

/**
 * Global guard (registered via APP_GUARD in AuthModule) — every route is
 * protected by default; @Public() explicitly opts out (docs/08_API.md §6).
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly reflector: Reflector,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractToken(request);
    if (!token) {
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'Missing access token',
      );
    }

    try {
      const payload: unknown = this.jwtService.verify(token);
      (request as AuthenticatedRequest).user =
        payload as AuthenticatedRequest['user'];
      return true;
    } catch (error) {
      if (error instanceof TokenExpiredError) {
        throw new AppException(
          HttpStatus.UNAUTHORIZED,
          'TOKEN_EXPIRED',
          'Access token has expired',
        );
      }
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'Invalid access token',
      );
    }
  }

  private extractToken(request: Request): string | null {
    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      return null;
    }
    return header.slice('Bearer '.length);
  }
}
