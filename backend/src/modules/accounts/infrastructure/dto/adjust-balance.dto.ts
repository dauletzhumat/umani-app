import { IsOptional, Matches, MaxLength } from 'class-validator';

// Signed — a correction can go either way (05_UX.md §5's "Расхождение
// баланса": the user may think there's more OR less money than recorded).
export class AdjustBalanceDto {
  @Matches(/^-?\d+(\.\d{1,2})?$/, {
    message: 'amount must be a signed decimal string',
  })
  amount!: string;

  @IsOptional()
  @MaxLength(500)
  note?: string;
}
