import { Injectable } from '@nestjs/common';
import { NotificationRepository } from '../../domain/repositories/notification.repository';
import { DeviceRepository } from '../../domain/repositories/device.repository';
import {
  FcmService,
  PushPayload,
} from '../../infrastructure/services/fcm.service';
import { Notification } from '../../domain/entities/notification.entity';

/** The "basic dispatcher" from T5.1's task card: persists a notification
 * row, then best-effort fans a push out to every device the user has
 * registered. A failed/unconfigured push never blocks persistence — the
 * in-app notification center (GET /notifications) is the source of
 * truth, push is a convenience on top. Consumed by later tasks (T6.2
 * budget alerts, T7.3 payment reminders) rather than by any T5.1 route
 * itself. */
@Injectable()
export class NotificationDispatcherService {
  constructor(
    private readonly notificationRepository: NotificationRepository,
    private readonly deviceRepository: DeviceRepository,
    private readonly fcmService: FcmService,
  ) {}

  async dispatch(
    userId: string,
    type: string,
    payload: Record<string, unknown>,
    push: PushPayload,
  ): Promise<Notification> {
    const notification = await this.notificationRepository.create({
      userId,
      type,
      payload,
    });

    const devices = await this.deviceRepository.findAllForUser(userId);
    await Promise.allSettled(
      devices.map((device) => this.fcmService.send(device.fcmToken, push)),
    );

    return notification;
  }
}
