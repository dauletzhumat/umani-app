import { IsIn, IsString, Matches, MaxLength } from 'class-validator';

const ACCOUNT_TYPES = ['cash', 'bank', 'card', 'multi_currency'] as const;

export class CreateAccountDto {
  @IsIn(ACCOUNT_TYPES)
  type!: (typeof ACCOUNT_TYPES)[number];

  @IsString()
  @MaxLength(100)
  name!: string;

  @Matches(/^[A-Z]{3}$/, {
    message: 'currency must be a 3-letter ISO 4217 code',
  })
  currency!: string;
}
