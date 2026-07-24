import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from '../../domain/entities/notification.entity';
import {
  NotificationCursor,
  NotificationRepository,
} from '../../domain/repositories/notification.repository';

@Injectable()
export class TypeOrmNotificationRepository implements NotificationRepository {
  constructor(
    @InjectRepository(Notification)
    private readonly repository: Repository<Notification>,
  ) {}

  create(data: {
    userId: string;
    type: string;
    payload: Record<string, unknown>;
  }): Promise<Notification> {
    return this.repository.save({
      userId: data.userId,
      type: data.type,
      payload: data.payload,
      sentAt: new Date(),
    });
  }

  findById(id: string): Promise<Notification | null> {
    return this.repository.findOne({ where: { id } });
  }

  async findAllForUser(
    userId: string,
    unreadOnly: boolean,
    cursor: NotificationCursor | null,
    limit: number,
  ): Promise<{ items: Notification[]; hasMore: boolean }> {
    const qb = this.repository
      .createQueryBuilder('notification')
      .where('notification.userId = :userId', { userId });

    if (unreadOnly) {
      qb.andWhere('notification.readAt IS NULL');
    }

    // Keyset pagination on the row's own (sentAt, id), same shape as
    // ListTransactionsUseCase — no OFFSET drift under concurrent inserts.
    if (cursor) {
      qb.andWhere(
        '(notification.sentAt, notification.id) < (:cursorSentAt, :cursorId)',
        { cursorSentAt: cursor.sentAt, cursorId: cursor.id },
      );
    }

    qb.orderBy('notification.sentAt', 'DESC')
      .addOrderBy('notification.id', 'DESC')
      .take(limit + 1);

    const rows = await qb.getMany();
    const hasMore = rows.length > limit;

    return { items: hasMore ? rows.slice(0, limit) : rows, hasMore };
  }

  async markRead(id: string): Promise<Notification> {
    await this.repository.update({ id }, { readAt: new Date() });
    const updated = await this.repository.findOne({ where: { id } });
    if (!updated) {
      throw new Error('Notification disappeared during update');
    }
    return updated;
  }
}
