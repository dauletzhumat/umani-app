import { IsIn, IsString, MaxLength } from 'class-validator';
import type { DevicePlatform } from '../../domain/entities/device.entity';

export class RegisterDeviceDto {
  @IsString()
  @MaxLength(255)
  fcmToken!: string;

  @IsIn(['ios', 'android'])
  platform!: DevicePlatform;
}
