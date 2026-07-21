import { IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateCategoryDto {
  @IsString()
  @MaxLength(100)
  name!: string;

  @IsString()
  @MaxLength(50)
  icon!: string;

  @IsOptional()
  @IsUUID()
  parentId?: string;
}
