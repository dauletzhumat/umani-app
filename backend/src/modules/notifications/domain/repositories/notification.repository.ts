import { Notification } from '../entities/notification.entity';

export interface NotificationCursor {
  id: string;
  sentAt: string;
}

export abstract class NotificationRepository {
  abstract create(data: {
    userId: string;
    type: string;
    payload: Record<string, unknown>;
  }): Promise<Notification>;

  abstract findById(id: string): Promise<Notification | null>;

  /** Keyset-paginated feed, newest first (docs/08_API.md §... GET
   * /notifications, mirrors ListTransactionsUseCase's cursor shape). */
  abstract findAllForUser(
    userId: string,
    unreadOnly: boolean,
    cursor: NotificationCursor | null,
    limit: number,
  ): Promise<{ items: Notification[]; hasMore: boolean }>;

  abstract markRead(id: string): Promise<Notification>;

  /** JSONB containment check — e.g. BudgetThresholdListener (T6.2) uses
   * this to dedupe {budgetId, threshold} before creating another one. */
  abstract existsByTypeAndPayload(
    userId: string,
    type: string,
    payloadMatch: Record<string, unknown>,
  ): Promise<boolean>;
}
