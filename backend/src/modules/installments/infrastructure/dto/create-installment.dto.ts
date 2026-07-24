import {
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateInstallmentDto {
  @IsString()
  @MaxLength(150)
  merchant!: string;

  @Matches(/^\d+(\.\d{1,2})?$/, {
    message: 'totalAmount must be a non-negative decimal string',
  })
  totalAmount!: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  installmentsCount!: number;

  @IsDateString()
  startDate!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  provider?: string;
}
