import {
  IsDateString,
  IsIn,
  IsOptional,
  IsUUID,
  Matches,
  MaxLength,
} from 'class-validator';

const TRANSACTION_TYPES = ['income', 'expense'] as const;
const TRANSACTION_SOURCES = ['manual', 'ocr', 'voice', 'import'] as const;

export class CreateTransactionDto {
  @IsUUID()
  accountId!: string;

  // Left unset here means "auto-categorize" (T4.4) — not implemented yet,
  // so it just stays null until that task wires the AI call in.
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @Matches(/^\d+(\.\d{1,2})?$/, {
    message: 'amount must be a non-negative decimal string',
  })
  amount!: string;

  @Matches(/^[A-Z]{3}$/, {
    message: 'currency must be a 3-letter ISO 4217 code',
  })
  currency!: string;

  @IsIn(TRANSACTION_TYPES)
  type!: (typeof TRANSACTION_TYPES)[number];

  @IsOptional()
  @IsDateString()
  occurredAt?: string;

  @IsOptional()
  @MaxLength(500)
  note?: string;

  @IsOptional()
  @IsIn(TRANSACTION_SOURCES)
  source?: (typeof TRANSACTION_SOURCES)[number];
}
