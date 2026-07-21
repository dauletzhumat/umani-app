import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { Account, AccountType } from '../../domain/entities/account.entity';
import { AccountRepository } from '../../domain/repositories/account.repository';

@Injectable()
export class TypeOrmAccountRepository implements AccountRepository {
  constructor(
    @InjectRepository(Account)
    private readonly repository: Repository<Account>,
  ) {}

  findAllForUser(userId: string): Promise<Account[]> {
    return this.repository.find({
      where: { userId, deletedAt: IsNull() },
      order: { createdAt: 'ASC' },
    });
  }

  findById(id: string): Promise<Account | null> {
    return this.repository.findOne({ where: { id, deletedAt: IsNull() } });
  }

  create(data: {
    userId: string;
    type: AccountType;
    name: string;
    currency: string;
  }): Promise<Account> {
    return this.repository.save({
      userId: data.userId,
      type: data.type,
      name: data.name,
      currency: data.currency,
    });
  }

  async update(
    id: string,
    changes: { name?: string; archived?: boolean },
  ): Promise<Account> {
    await this.repository.update({ id }, changes);
    const updated = await this.repository.findOne({ where: { id } });
    if (!updated) {
      throw new Error('Account disappeared during update');
    }
    return updated;
  }

  async softDelete(id: string): Promise<void> {
    await this.repository.update({ id }, { deletedAt: new Date() });
  }
}
