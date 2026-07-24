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
import { RegisterDeviceUseCase } from '../../application/use-cases/register-device.use-case';
import { DeleteDeviceUseCase } from '../../application/use-cases/delete-device.use-case';
import { ListNotificationsUseCase } from '../../application/use-cases/list-notifications.use-case';
import { MarkNotificationReadUseCase } from '../../application/use-cases/mark-notification-read.use-case';
import { RegisterDeviceDto } from '../dto/register-device.dto';
import { ListNotificationsDto } from '../dto/list-notifications.dto';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller()
export class NotificationsController {
  constructor(
    private readonly registerDeviceUseCase: RegisterDeviceUseCase,
    private readonly deleteDeviceUseCase: DeleteDeviceUseCase,
    private readonly listNotificationsUseCase: ListNotificationsUseCase,
    private readonly markNotificationReadUseCase: MarkNotificationReadUseCase,
  ) {}

  @Post('devices')
  registerDevice(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: RegisterDeviceDto,
  ) {
    return this.registerDeviceUseCase.execute(user.sub, dto);
  }

  @Delete('devices/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteDevice(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.deleteDeviceUseCase.execute(user.sub, id);
  }

  @Get('notifications')
  listNotifications(
    @CurrentUser() user: AccessTokenPayload,
    @Query() query: ListNotificationsDto,
  ) {
    return this.listNotificationsUseCase.execute(user.sub, query);
  }

  @Patch('notifications/:id/read')
  markRead(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.markNotificationReadUseCase.execute(user.sub, id);
  }
}
