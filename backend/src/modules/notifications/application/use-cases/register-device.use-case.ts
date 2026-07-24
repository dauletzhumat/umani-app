import { Injectable } from '@nestjs/common';
import { DeviceRepository } from '../../domain/repositories/device.repository';
import { Device } from '../../domain/entities/device.entity';
import { RegisterDeviceDto } from '../../infrastructure/dto/register-device.dto';

@Injectable()
export class RegisterDeviceUseCase {
  constructor(private readonly deviceRepository: DeviceRepository) {}

  execute(userId: string, dto: RegisterDeviceDto): Promise<Device> {
    return this.deviceRepository.upsert({
      userId,
      fcmToken: dto.fcmToken,
      platform: dto.platform,
    });
  }
}
