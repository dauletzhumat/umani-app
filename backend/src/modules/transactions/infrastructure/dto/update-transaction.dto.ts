import {
  IsDateString,
  IsIn,
  IsOptional,
  IsUUID,
  Matches,
  MaxLength,
} from 'class-validator';

const TRANSACTION_TYPES = ['income', 'expense'] as const;

// accountId is intentionally not editable — moving a transaction between
// accounts isn't in docs/08_API.md §10's spec and adds balance-transfer
// complexity out of scope for this task.
export class UpdateTransactionDto {
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @Matches(/^\d+(\.\d{1,2})?$/, {
    message: 'amount must be a non-negative decimal string',
  })
  amount?: string;

  @IsOptional()
  @Matches(/^[A-Z]{3}$/, {
    message: 'currency must be a 3-letter ISO 4217 code',
  })
  currency?: string;

  @IsOptional()
  @IsIn(TRANSACTION_TYPES)
  type?: (typeof TRANSACTION_TYPES)[number];

  @IsOptional()
  @IsDateString()
  occurredAt?: string;

  @IsOptional()
  @MaxLength(500)
  note?: string;
}
