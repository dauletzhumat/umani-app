import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { Installment } from '../../domain/entities/installment.entity';
import { InstallmentRepository } from '../../domain/repositories/installment.repository';

@Injectable()
export class TypeOrmInstallmentRepository implements InstallmentRepository {
  constructor(
    @InjectRepository(Installment)
    private readonly repository: Repository<Installment>,
  ) {}

  create(data: {
    userId: string;
    merchant: string;
    totalAmount: string;
    installmentsCount: number;
    startDate: string;
    provider: string | null;
  }): Promise<Installment> {
    return this.repository.save({
      userId: data.userId,
      merchant: data.merchant,
      totalAmount: data.totalAmount,
      installmentsCount: data.installmentsCount,
      startDate: data.startDate,
      provider: data.provider,
    });
  }

  findAllForUser(userId: string): Promise<Installment[]> {
    return this.repository.find({ where: { userId, deletedAt: IsNull() } });
  }

  findById(id: string): Promise<Installment | null> {
    return this.repository.findOne({ where: { id, deletedAt: IsNull() } });
  }

  findByIds(ids: string[]): Promise<Installment[]> {
    if (ids.length === 0) return Promise.resolve([]);
    return this.repository.find({ where: { id: In(ids) } });
  }
}
