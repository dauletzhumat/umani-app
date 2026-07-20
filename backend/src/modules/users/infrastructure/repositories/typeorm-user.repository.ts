import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../domain/entities/user.entity';
import { UserRepository } from '../../domain/repositories/user.repository';

@Injectable()
export class TypeOrmUserRepository implements UserRepository {
  constructor(
    @InjectRepository(User)
    private readonly repository: Repository<User>,
  ) {}

  async findActiveByIdentifier(identifier: {
    phone: string | null;
    email: string | null;
  }): Promise<User | null> {
    const qb = this.repository
      .createQueryBuilder('user')
      .where('user.deletedAt IS NULL');

    if (identifier.phone) {
      qb.andWhere('user.phone = :phone', { phone: identifier.phone });
    } else if (identifier.email) {
      qb.andWhere('LOWER(user.email) = LOWER(:email)', {
        email: identifier.email,
      });
    } else {
      return null;
    }

    return qb.getOne();
  }

  async create(identifier: {
    phone: string | null;
    email: string | null;
  }): Promise<User> {
    return this.repository.save({
      phone: identifier.phone,
      email: identifier.email,
      locale: 'ru',
      defaultCurrency: 'KZT',
    });
  }
}
