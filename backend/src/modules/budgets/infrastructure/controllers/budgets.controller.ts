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
import { CreateBudgetUseCase } from '../../application/use-cases/create-budget.use-case';
import { GetBudgetsUseCase } from '../../application/use-cases/get-budgets.use-case';
import { UpdateBudgetUseCase } from '../../application/use-cases/update-budget.use-case';
import { DeleteBudgetUseCase } from '../../application/use-cases/delete-budget.use-case';
import { CreateBudgetDto } from '../dto/create-budget.dto';
import { UpdateBudgetDto } from '../dto/update-budget.dto';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller('budgets')
export class BudgetsController {
  constructor(
    private readonly createBudgetUseCase: CreateBudgetUseCase,
    private readonly getBudgetsUseCase: GetBudgetsUseCase,
    private readonly updateBudgetUseCase: UpdateBudgetUseCase,
    private readonly deleteBudgetUseCase: DeleteBudgetUseCase,
  ) {}

  @Get()
  findAll(@CurrentUser() user: AccessTokenPayload) {
    return this.getBudgetsUseCase.execute(user.sub);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: CreateBudgetDto,
  ) {
    return this.createBudgetUseCase.execute(user.sub, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateBudgetDto,
  ) {
    return this.updateBudgetUseCase.execute(user.sub, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  delete(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.deleteBudgetUseCase.execute(user.sub, id);
  }
}
