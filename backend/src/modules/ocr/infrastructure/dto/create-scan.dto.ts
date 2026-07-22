import { IsString, MaxLength } from 'class-validator';

export class CreateScanDto {
  @IsString()
  @MaxLength(500)
  storagePath!: string;
}
