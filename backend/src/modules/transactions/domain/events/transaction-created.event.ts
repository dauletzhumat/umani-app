import { TransactionType } from '../entities/transaction.entity';

export const TRANSACTION_CREATED_EVENT = 'transaction.created';

/** Only the fields BudgetThresholdListener (T6.2) actually needs — not
 * the full Transaction entity, so listeners stay decoupled from its shape. */
export class TransactionCreatedEvent {
  constructor(
    public readonly userId: string,
    public readonly categoryId: string | null,
    public readonly type: TransactionType,
    public readonly occurredAt: string,
  ) {}
}
