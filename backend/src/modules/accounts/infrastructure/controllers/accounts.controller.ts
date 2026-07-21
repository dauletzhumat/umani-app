import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { AccountRepository } from '../../domain/repositories/account.repository';
import { CreateAccountUseCase } from '../../application/use-cases/create-account.use-case';
import { UpdateAccountUseCase } from '../../application/use-cases/update-account.use-case';
import { DeleteAccountUseCase } from '../../application/use-cases/delete-account.use-case';
import { AdjustBalanceUseCase } from '../../application/use-cases/adjust-balance.use-case';
import { CreateAccountDto } from '../dto/create-account.dto';
import { UpdateAccountDto } from '../dto/update-account.dto';
import { AdjustBalanceDto } from '../dto/adjust-balance.dto';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import { AppException } from '../../../../shared/exceptions/app.exception';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller('accounts')
export class AccountsController {
  constructor(
    private readonly accountRepository: AccountRepository,
    private readonly createAccountUseCase: CreateAccountUseCase,
    private readonly updateAccountUseCase: UpdateAccountUseCase,
    private readonly deleteAccountUseCase: DeleteAccountUseCase,
    private readonly adjustBalanceUseCase: AdjustBalanceUseCase,
  ) {}

  @Get()
  findAll(@CurrentUser() user: AccessTokenPayload) {
    return this.accountRepository.findAllForUser(user.sub);
  }

  @Get(':id')
  async findOne(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    const account = await this.accountRepository.findById(id);
    if (!account || account.userId !== user.sub) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Account not found',
      );
    }
    return account;
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: CreateAccountDto,
  ) {
    return this.createAccountUseCase.execute(user.sub, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAccountDto,
  ) {
    return this.updateAccountUseCase.execute(user.sub, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  delete(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.deleteAccountUseCase.execute(user.sub, id);
  }

  @Post(':id/adjust-balance')
  @HttpCode(HttpStatus.CREATED)
  adjustBalance(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AdjustBalanceDto,
  ) {
    return this.adjustBalanceUseCase.execute(user.sub, id, dto);
  }
}
