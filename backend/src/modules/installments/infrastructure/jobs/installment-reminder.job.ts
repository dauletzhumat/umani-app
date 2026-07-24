import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { Cron, CronExpression, SchedulerRegistry } from '@nestjs/schedule';
import { InstallmentRepository } from '../../domain/repositories/installment.repository';
import { InstallmentPaymentRepository } from '../../domain/repositories/installment-payment.repository';
import { InstallmentPayment } from '../../domain/entities/installment-payment.entity';
import { UserRepository } from '../../../users/domain/repositories/user.repository';
import { NotificationRepository } from '../../../notifications/domain/repositories/notification.repository';
import { NotificationDispatcherService } from '../../../notifications/application/services/notification-dispatcher.service';

const NOTIFICATION_TYPE = 'installment_payment_reminder';
const CRON_JOB_NAME = 'installment-reminder';

// Amount+merchant+due date instead of "in N days" — sidesteps ru's
// three-way plural agreement (1 день / 2-4 дня / 5+ дней) entirely.
const COPY: Record<
  string,
  {
    title: string;
    body: (merchant: string, amount: string, dueDate: string) => string;
  }
> = {
  ru: {
    title: 'Рассрочка',
    body: (merchant, amount, dueDate) =>
      `Платёж ${amount} по рассрочке «${merchant}» — до ${dueDate}`,
  },
  kk: {
    title: 'Бөліп төлеу',
    body: (merchant, amount, dueDate) =>
      `«${merchant}» бөліп төлеуі бойынша ${amount} төлемі — ${dueDate} дейін`,
  },
  en: {
    title: 'Installment',
    body: (merchant, amount, dueDate) =>
      `${amount} payment for "${merchant}" — due ${dueDate}`,
  },
};

/** Daily cron (docs/06_Architecture.md §12); MVP runs this in-process via
 * @nestjs/schedule rather than enqueueing onto a BullMQ worker — no
 * queue consumer exists anywhere in this codebase yet
 * (Development_Tasks.md §0). Notifies once per payment (deduped via
 * NotificationRepository.existsByTypeAndPayload, same mechanism as
 * T6.2's budget thresholds) — without that, a payment due in 3 days
 * would renotify every day it stays inside the 1-3-day window.
 *
 * @nestjs/schedule's CronJob timer isn't stopped by app.close() on its
 * own (no built-in destroy hook) — left running, it keeps the Node
 * event loop alive, which hangs the e2e test process after all suites
 * finish. OnModuleDestroy explicitly stops it, same shape as
 * RedisLifecycle in shared/redis/redis.module.ts. */
@Injectable()
export class InstallmentReminderJob implements OnModuleDestroy {
  private readonly logger = new Logger(InstallmentReminderJob.name);

  constructor(
    private readonly installmentRepository: InstallmentRepository,
    private readonly installmentPaymentRepository: InstallmentPaymentRepository,
    private readonly userRepository: UserRepository,
    private readonly notificationRepository: NotificationRepository,
    private readonly notificationDispatcherService: NotificationDispatcherService,
    private readonly schedulerRegistry: SchedulerRegistry,
  ) {}

  async onModuleDestroy(): Promise<void> {
    await this.schedulerRegistry.getCronJob(CRON_JOB_NAME).stop();
  }

  // unrefTimeout: the underlying `cron` package's setTimeout keeps
  // Node's event loop alive by default (it "controls" the process) —
  // unref lets the process (and, critically, the e2e test run, which
  // creates a fresh app/timer per test file) exit normally instead of
  // hanging on a timer that only ever fires at the next midnight.
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT, {
    name: CRON_JOB_NAME,
    unrefTimeout: true,
  })
  async run(): Promise<void> {
    try {
      await this.remindDuePayments();
    } catch (error) {
      this.logger.error(
        `installment-reminder job failed: ${(error as Error).message}`,
      );
    }
  }

  private async remindDuePayments(): Promise<void> {
    const [dateFrom, dateTo] = this.reminderWindow();
    const duePayments =
      await this.installmentPaymentRepository.findPendingDueBetween(
        dateFrom,
        dateTo,
      );
    if (duePayments.length === 0) return;

    const installments = await this.installmentRepository.findByIds([
      ...new Set(duePayments.map((payment) => payment.installmentId)),
    ]);
    const installmentById = new Map(
      installments.map((installment) => [installment.id, installment]),
    );

    for (const payment of duePayments) {
      const installment = installmentById.get(payment.installmentId);
      if (!installment) continue;

      const alreadyNotified =
        await this.notificationRepository.existsByTypeAndPayload(
          installment.userId,
          NOTIFICATION_TYPE,
          { paymentId: payment.id },
        );
      if (alreadyNotified) continue;

      await this.notify(installment.userId, installment.merchant, payment);
    }
  }

  /** [today+1, today+3] inclusive — "1-3 days before due_date". */
  private reminderWindow(): [string, string] {
    const now = new Date();
    const from = new Date(now);
    from.setUTCDate(from.getUTCDate() + 1);
    const to = new Date(now);
    to.setUTCDate(to.getUTCDate() + 3);
    return [formatDate(from), formatDate(to)];
  }

  private async notify(
    userId: string,
    merchant: string,
    payment: InstallmentPayment,
  ): Promise<void> {
    const user = await this.userRepository.findById(userId);
    const locale = user?.locale ?? 'ru';
    const copy = COPY[locale] ?? COPY.ru;

    try {
      await this.notificationDispatcherService.dispatch(
        userId,
        NOTIFICATION_TYPE,
        {
          installmentId: payment.installmentId,
          paymentId: payment.id,
          dueDate: payment.dueDate,
        },
        {
          title: copy.title,
          body: copy.body(merchant, payment.amount, payment.dueDate),
        },
      );
    } catch (error) {
      this.logger.warn(
        `Failed to dispatch installment_payment_reminder: ${(error as Error).message}`,
      );
    }
  }
}

function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}
