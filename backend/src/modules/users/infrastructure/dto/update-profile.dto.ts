import {
  IsIn,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsIn(['ru', 'kk', 'en'])
  locale?: string;

  // ISO 4217 alpha code. No dedicated CHECK on users.default_currency in the
  // schema (unlike accounts later) — 07_Database.md §1 says currency is
  // "validated at the application level", hence the format check here.
  @IsOptional()
  @Matches(/^[A-Z]{3}$/, {
    message: 'defaultCurrency must be a 3-letter ISO 4217 code',
  })
  defaultCurrency?: string;
}
