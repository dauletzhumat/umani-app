import { HttpStatus, Injectable } from '@nestjs/common';
import { AccountRepository } from '../../domain/repositories/account.repository';
import { Account } from '../../domain/entities/account.entity';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { UpdateAccountDto } from '../../infrastructure/dto/update-account.dto';

@Injectable()
export class UpdateAccountUseCase {
  constructor(private readonly accountRepository: AccountRepository) {}

  async execute(
    userId: string,
    accountId: string,
    dto: UpdateAccountDto,
  ): Promise<Account> {
    const account = await this.accountRepository.findById(accountId);

    // Another user's account is masked as NOT_FOUND (08_API.md §5).
    if (!account || account.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Account not found',
      );
    }

    return this.accountRepository.update(accountId, {
      name: dto.name,
      archived: dto.archived,
    });
  }
}
