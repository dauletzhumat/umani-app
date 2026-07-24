import { HttpStatus, Injectable } from '@nestjs/common';
import { NotificationRepository } from '../../domain/repositories/notification.repository';
import { Notification } from '../../domain/entities/notification.entity';
import { AppException } from '../../../../shared/exceptions/app.exception';

@Injectable()
export class MarkNotificationReadUseCase {
  constructor(
    private readonly notificationRepository: NotificationRepository,
  ) {}

  async execute(userId: string, id: string): Promise<Notification> {
    const notification = await this.notificationRepository.findById(id);

    if (!notification || notification.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Notification not found',
      );
    }

    return this.notificationRepository.markRead(id);
  }
}
