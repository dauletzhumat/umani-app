import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Device } from './domain/entities/device.entity';
import { Notification } from './domain/entities/notification.entity';
import { DeviceRepository } from './domain/repositories/device.repository';
import { TypeOrmDeviceRepository } from './infrastructure/repositories/device.repository';
import { NotificationRepository } from './domain/repositories/notification.repository';
import { TypeOrmNotificationRepository } from './infrastructure/repositories/notification.repository';
import { FcmService } from './infrastructure/services/fcm.service';
import { NotificationDispatcherService } from './application/services/notification-dispatcher.service';
import { RegisterDeviceUseCase } from './application/use-cases/register-device.use-case';
import { DeleteDeviceUseCase } from './application/use-cases/delete-device.use-case';
import { ListNotificationsUseCase } from './application/use-cases/list-notifications.use-case';
import { MarkNotificationReadUseCase } from './application/use-cases/mark-notification-read.use-case';
import { NotificationsController } from './infrastructure/controllers/notifications.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Device, Notification])],
  controllers: [NotificationsController],
  providers: [
    { provide: DeviceRepository, useClass: TypeOrmDeviceRepository },
    {
      provide: NotificationRepository,
      useClass: TypeOrmNotificationRepository,
    },
    FcmService,
    NotificationDispatcherService,
    RegisterDeviceUseCase,
    DeleteDeviceUseCase,
    ListNotificationsUseCase,
    MarkNotificationReadUseCase,
  ],
  // NotificationDispatcherService is what T6.2/T7.3 will import this
  // module for — repositories are exported too in case a future module
  // needs read access without going through the dispatcher.
  exports: [
    NotificationDispatcherService,
    DeviceRepository,
    NotificationRepository,
  ],
})
export class NotificationsModule {}
