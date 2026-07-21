import { Injectable } from '@nestjs/common';
import { AccountRepository } from '../../domain/repositories/account.repository';
import { Account } from '../../domain/entities/account.entity';
import { CreateAccountDto } from '../../infrastructure/dto/create-account.dto';

@Injectable()
export class CreateAccountUseCase {
  constructor(private readonly accountRepository: AccountRepository) {}

  execute(userId: string, dto: CreateAccountDto): Promise<Account> {
    return this.accountRepository.create({
      userId,
      type: dto.type,
      name: dto.name,
      currency: dto.currency,
    });
  }
}
