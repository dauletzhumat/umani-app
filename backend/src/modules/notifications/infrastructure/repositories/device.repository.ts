import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Device, DevicePlatform } from '../../domain/entities/device.entity';
import { DeviceRepository } from '../../domain/repositories/device.repository';

@Injectable()
export class TypeOrmDeviceRepository implements DeviceRepository {
  constructor(
    @InjectRepository(Device)
    private readonly repository: Repository<Device>,
  ) {}

  async upsert(data: {
    userId: string;
    fcmToken: string;
    platform: DevicePlatform;
  }): Promise<Device> {
    // Atomic upsert on uq_devices_user_token rather than
    // find-then-save — avoids a race between two concurrent
    // registrations of the same token duplicating the row.
    await this.repository
      .createQueryBuilder()
      .insert()
      .values({
        userId: data.userId,
        fcmToken: data.fcmToken,
        platform: data.platform,
        lastActiveAt: new Date(),
      })
      .orUpdate(['platform', 'last_active_at'], ['user_id', 'fcm_token'])
      .execute();

    const device = await this.repository.findOne({
      where: { userId: data.userId, fcmToken: data.fcmToken },
    });
    if (!device) {
      throw new Error('Device disappeared during upsert');
    }
    return device;
  }

  findById(id: string): Promise<Device | null> {
    return this.repository.findOne({ where: { id } });
  }

  findAllForUser(userId: string): Promise<Device[]> {
    return this.repository.find({ where: { userId } });
  }

  async deleteById(id: string): Promise<void> {
    await this.repository.delete({ id });
  }
}
