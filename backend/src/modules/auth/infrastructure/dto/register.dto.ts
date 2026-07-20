import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  identifier!: string;

  // Not persisted in T1.2 — users aren't created until /auth/otp/verify
  // (T1.3), which has no locale field of its own in docs/08_API.md yet.
  @IsOptional()
  @IsIn(['ru', 'kk', 'en'])
  locale?: string;
}
