import { Injectable } from '@nestjs/common';
import {
  NotificationCursor,
  NotificationRepository,
} from '../../domain/repositories/notification.repository';
import { Notification } from '../../domain/entities/notification.entity';
import { PaginatedResult } from '../../../../shared/types/paginated-result';
import { ListNotificationsDto } from '../../infrastructure/dto/list-notifications.dto';

const DEFAULT_LIMIT = 20;

@Injectable()
export class ListNotificationsUseCase {
  constructor(
    private readonly notificationRepository: NotificationRepository,
  ) {}

  async execute(
    userId: string,
    dto: ListNotificationsDto,
  ): Promise<PaginatedResult<Notification>> {
    const limit = dto.limit ?? DEFAULT_LIMIT;
    const cursor = decodeCursor(dto.cursor);

    const { items, hasMore } = await this.notificationRepository.findAllForUser(
      userId,
      dto.unreadOnly ?? false,
      cursor,
      limit,
    );

    return {
      data: items,
      meta: {
        nextCursor: hasMore ? encodeCursor(items[items.length - 1]) : null,
        hasMore,
        limit,
      },
    };
  }
}

// Malformed cursors are treated as "no cursor" — opaque to the client,
// same contract as ListTransactionsUseCase (docs/08_API.md §4).
function decodeCursor(cursor?: string): NotificationCursor | null {
  if (!cursor) return null;
  try {
    const decoded = JSON.parse(
      Buffer.from(cursor, 'base64').toString('utf8'),
    ) as Partial<NotificationCursor>;
    if (typeof decoded.id !== 'string' || typeof decoded.sentAt !== 'string') {
      return null;
    }
    return { id: decoded.id, sentAt: decoded.sentAt };
  } catch {
    return null;
  }
}

function encodeCursor(notification: Notification): string {
  const cursor: NotificationCursor = {
    id: notification.id,
    sentAt: notification.sentAt.toISOString(),
  };
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64');
}
