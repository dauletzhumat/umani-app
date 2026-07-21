import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

/** Rename/archive only, per docs/08_API.md §8. */
export class UpdateAccountDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsBoolean()
  archived?: boolean;
}
