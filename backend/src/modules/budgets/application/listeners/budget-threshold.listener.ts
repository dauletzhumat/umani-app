import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { BudgetRepository } from '../../domain/repositories/budget.repository';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import { UserRepository } from '../../../users/domain/repositories/user.repository';
import { NotificationRepository } from '../../../notifications/domain/repositories/notification.repository';
import { NotificationDispatcherService } from '../../../notifications/application/services/notification-dispatcher.service';
import {
  BudgetProgressService,
  isWithinBudgetPeriod,
} from '../services/budget-progress.service';
import {
  TRANSACTION_CREATED_EVENT,
  TransactionCreatedEvent,
} from '../../../transactions/domain/events/transaction-created.event';

const THRESHOLDS = [80, 100] as const;
type Threshold = (typeof THRESHOLDS)[number];

const NOTIFICATION_TYPE = 'budget_threshold';

// Server-generated push text — mirrors the client's localization tables
// (there's no client rendering this one, unlike API error codes) and
// 05_UX.md's non-judgmental copy principle ("Вы близки к лимиту", not
// "Вы превышаете бюджет").
const COPY: Record<
  string,
  Record<Threshold, { title: string; body: (categoryName: string) => string }>
> = {
  ru: {
    80: {
      title: 'Бюджет',
      body: (name) => `Вы близки к лимиту по категории «${name}»`,
    },
    100: {
      title: 'Бюджет',
      body: (name) => `Лимит бюджета по категории «${name}» исчерпан`,
    },
  },
  kk: {
    80: {
      title: 'Бюджет',
      body: (name) => `«${name}» санаты бойынша лимитке жақындадыңыз`,
    },
    100: {
      title: 'Бюджет',
      body: (name) => `«${name}» санаты бойынша бюджет лимиті таусылды`,
    },
  },
  en: {
    80: {
      title: 'Budget',
      body: (name) => `You're close to your budget limit for "${name}"`,
    },
    100: {
      title: 'Budget',
      body: (name) => `Your budget limit for "${name}" has been reached`,
    },
  },
};

/** Notifies on crossing 80% and, independently, 100% of a budget's
 * limit — each threshold notifies at most once per budget (T6.2). Since
 * every budget row is already scoped to a single period
 * (uq_budgets_user_category_period, T6.1), "once per period" is just
 * "once per (budgetId, threshold)". */
@Injectable()
export class BudgetThresholdListener {
  private readonly logger = new Logger(BudgetThresholdListener.name);

  constructor(
    private readonly budgetRepository: BudgetRepository,
    private readonly categoryRepository: CategoryRepository,
    private readonly userRepository: UserRepository,
    private readonly notificationRepository: NotificationRepository,
    private readonly notificationDispatcherService: NotificationDispatcherService,
    private readonly budgetProgressService: BudgetProgressService,
  ) {}

  // CreateTransactionUseCase awaits this via emitAsync so the response
  // only returns once this has finished — still wrapped in try/catch so
  // a check/dispatch failure can't turn into a failed transaction create.
  @OnEvent(TRANSACTION_CREATED_EVENT)
  async handle(event: TransactionCreatedEvent): Promise<void> {
    try {
      if (event.type !== 'expense' || !event.categoryId) return;

      const budgets = await this.budgetRepository.findAllForUserAndCategory(
        event.userId,
        event.categoryId,
      );
      const affected = budgets.filter((budget) =>
        isWithinBudgetPeriod(budget, event.occurredAt),
      );
      if (affected.length === 0) return;

      const category = await this.categoryRepository.findById(event.categoryId);
      const categoryName = category?.name ?? '';

      for (const budget of affected) {
        const progress = await this.budgetProgressService.computeProgress(
          budget,
          categoryName,
        );

        for (const threshold of THRESHOLDS) {
          if (progress.progressPercent < threshold) continue;

          const alreadyNotified =
            await this.notificationRepository.existsByTypeAndPayload(
              event.userId,
              NOTIFICATION_TYPE,
              { budgetId: budget.id, threshold },
            );
          if (alreadyNotified) continue;

          await this.notify(event.userId, budget.id, threshold, categoryName);
        }
      }
    } catch (error) {
      this.logger.warn(
        `budget_threshold check failed: ${(error as Error).message}`,
      );
    }
  }

  private async notify(
    userId: string,
    budgetId: string,
    threshold: Threshold,
    categoryName: string,
  ): Promise<void> {
    const user = await this.userRepository.findById(userId);
    const locale = user?.locale ?? 'ru';
    const copy = (COPY[locale] ?? COPY.ru)[threshold];

    try {
      await this.notificationDispatcherService.dispatch(
        userId,
        NOTIFICATION_TYPE,
        { budgetId, threshold },
        { title: copy.title, body: copy.body(categoryName) },
      );
    } catch (error) {
      // A notification failure shouldn't fail the transaction that
      // triggered it — the listener runs after the transaction already
      // committed.
      this.logger.warn(
        `Failed to dispatch budget_threshold notification: ${(error as Error).message}`,
      );
    }
  }
}
