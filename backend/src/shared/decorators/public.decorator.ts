import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Explicit opt-out of the global JwtAuthGuard (docs/08_API.md §6:
 * "explicit allow" is safer than "explicit deny" for auth).
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
