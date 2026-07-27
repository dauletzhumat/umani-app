import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './domain/entities/user.entity';
import { UserRepository } from './domain/repositories/user.repository';
import { TypeOrmUserRepository } from './infrastructure/repositories/typeorm-user.repository';
import { GetProfileUseCase } from './application/use-cases/get-profile.use-case';
import { UpdateProfileUseCase } from './application/use-cases/update-profile.use-case';
import { DeleteAccountUseCase } from './application/use-cases/delete-account.use-case';
import { UsersController } from './infrastructure/controllers/users.controller';
import { RefreshToken } from '../auth/domain/entities/refresh-token.entity';
import { RefreshTokenRepository } from '../auth/domain/repositories/refresh-token.repository';
import { TypeOrmRefreshTokenRepository } from '../auth/infrastructure/repositories/refresh-token.repository';

@Module({
  // RefreshToken/RefreshTokenRepository bound here too (alongside
  // AuthModule's own identical binding) — AuthModule imports UsersModule,
  // so the reverse import would be circular; DeleteAccountUseCase needs
  // to revoke every session on account deletion.
  imports: [TypeOrmModule.forFeature([User, RefreshToken])],
  controllers: [UsersController],
  providers: [
    { provide: UserRepository, useClass: TypeOrmUserRepository },
    {
      provide: RefreshTokenRepository,
      useClass: TypeOrmRefreshTokenRepository,
    },
    GetProfileUseCase,
    UpdateProfileUseCase,
    DeleteAccountUseCase,
  ],
  exports: [UserRepository],
})
export class UsersModule {}
