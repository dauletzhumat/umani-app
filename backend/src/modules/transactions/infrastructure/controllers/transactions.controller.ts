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
  Query,
} from '@nestjs/common';
import { TransactionRepository } from '../../domain/repositories/transaction.repository';
import { CreateTransactionUseCase } from '../../application/use-cases/create-transaction.use-case';
import { ListTransactionsUseCase } from '../../application/use-cases/list-transactions.use-case';
import { UpdateTransactionUseCase } from '../../application/use-cases/update-transaction.use-case';
import { DeleteTransactionUseCase } from '../../application/use-cases/delete-transaction.use-case';
import { CreateTransactionDto } from '../dto/create-transaction.dto';
import { UpdateTransactionDto } from '../dto/update-transaction.dto';
import { ListTransactionsDto } from '../dto/list-transactions.dto';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import { AppException } from '../../../../shared/exceptions/app.exception';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller('transactions')
export class TransactionsController {
  constructor(
    private readonly transactionRepository: TransactionRepository,
    private readonly createTransactionUseCase: CreateTransactionUseCase,
    private readonly listTransactionsUseCase: ListTransactionsUseCase,
    private readonly updateTransactionUseCase: UpdateTransactionUseCase,
    private readonly deleteTransactionUseCase: DeleteTransactionUseCase,
  ) {}

  @Get()
  findAll(
    @CurrentUser() user: AccessTokenPayload,
    @Query() query: ListTransactionsDto,
  ) {
    return this.listTransactionsUseCase.execute(user.sub, query);
  }

  @Get(':id')
  async findOne(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    const transaction = await this.transactionRepository.findById(id);
    if (!transaction || transaction.userId !== user.sub) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Transaction not found',
      );
    }
    return transaction;
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: CreateTransactionDto,
  ) {
    return this.createTransactionUseCase.execute(user.sub, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateTransactionDto,
  ) {
    return this.updateTransactionUseCase.execute(user.sub, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  delete(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.deleteTransactionUseCase.execute(user.sub, id);
  }
}
