import { HttpStatus, Injectable } from '@nestjs/common';
import { AccountRepository } from '../../domain/repositories/account.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';

@Injectable()
export class DeleteAccountUseCase {
  constructor(private readonly accountRepository: AccountRepository) {}

  async execute(userId: string, accountId: string): Promise<void> {
    const account = await this.accountRepository.findById(accountId);

    if (!account || account.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Account not found',
      );
    }

    await this.accountRepository.softDelete(accountId);
  }
}
