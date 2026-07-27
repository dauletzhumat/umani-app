import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
} from '@nestjs/common';
import { GetProfileUseCase } from '../../application/use-cases/get-profile.use-case';
import { UpdateProfileUseCase } from '../../application/use-cases/update-profile.use-case';
import { DeleteAccountUseCase } from '../../application/use-cases/delete-account.use-case';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller('users')
export class UsersController {
  constructor(
    private readonly getProfileUseCase: GetProfileUseCase,
    private readonly updateProfileUseCase: UpdateProfileUseCase,
    private readonly deleteAccountUseCase: DeleteAccountUseCase,
  ) {}

  @Get('me')
  getMe(@CurrentUser() user: AccessTokenPayload) {
    return this.getProfileUseCase.execute(user.sub);
  }

  @Patch('me')
  updateMe(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.updateProfileUseCase.execute(user.sub, dto);
  }

  @Delete('me')
  @HttpCode(HttpStatus.ACCEPTED)
  deleteMe(@CurrentUser() user: AccessTokenPayload) {
    return this.deleteAccountUseCase.execute(user.sub);
  }
}
