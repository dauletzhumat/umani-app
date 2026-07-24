import { Device, DevicePlatform } from '../entities/device.entity';

export abstract class DeviceRepository {
  /** Idempotent registration keyed on (userId, fcmToken) —
   * uq_devices_user_token (docs/07_Database.md §5.20). Re-registering the
   * same token refreshes platform/lastActiveAt instead of duplicating. */
  abstract upsert(data: {
    userId: string;
    fcmToken: string;
    platform: DevicePlatform;
  }): Promise<Device>;

  abstract findById(id: string): Promise<Device | null>;

  abstract findAllForUser(userId: string): Promise<Device[]>;

  abstract deleteById(id: string): Promise<void>;
}
