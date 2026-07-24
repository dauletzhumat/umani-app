import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class ListNotificationsDto {
  // Query params arrive as strings — Boolean('false') is truthy, so this
  // needs an explicit string comparison rather than @Type(() => Boolean).
  @IsOptional()
  @Transform(({ value }) => value === 'true')
  @IsBoolean()
  unreadOnly?: boolean;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  // Opaque to the client (docs/08_API.md §4) — decoded server-side only.
  @IsOptional()
  @IsString()
  cursor?: string;
}
