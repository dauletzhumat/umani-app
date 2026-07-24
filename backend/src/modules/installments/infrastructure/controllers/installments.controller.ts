import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { CreateInstallmentUseCase } from '../../application/use-cases/create-installment.use-case';
import { GetInstallmentsUseCase } from '../../application/use-cases/get-installments.use-case';
import { CreateInstallmentDto } from '../dto/create-installment.dto';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller('installments')
export class InstallmentsController {
  constructor(
    private readonly createInstallmentUseCase: CreateInstallmentUseCase,
    private readonly getInstallmentsUseCase: GetInstallmentsUseCase,
  ) {}

  @Get()
  findAll(@CurrentUser() user: AccessTokenPayload) {
    return this.getInstallmentsUseCase.execute(user.sub);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: CreateInstallmentDto,
  ) {
    return this.createInstallmentUseCase.execute(user.sub, dto);
  }
}
