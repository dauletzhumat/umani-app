import { HttpStatus, Injectable } from '@nestjs/common';
import { DeviceRepository } from '../../domain/repositories/device.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';

@Injectable()
export class DeleteDeviceUseCase {
  constructor(private readonly deviceRepository: DeviceRepository) {}

  async execute(userId: string, deviceId: string): Promise<void> {
    const device = await this.deviceRepository.findById(deviceId);

    if (!device || device.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Device not found',
      );
    }

    await this.deviceRepository.deleteById(deviceId);
  }
}
