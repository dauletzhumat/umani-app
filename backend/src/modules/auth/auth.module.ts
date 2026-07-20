import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { OtpCode } from './domain/entities/otp-code.entity';
import { RefreshToken } from './domain/entities/refresh-token.entity';
import { OtpCodeRepository } from './domain/repositories/otp-code.repository';
import { RefreshTokenRepository } from './domain/repositories/refresh-token.repository';
import { TypeOrmOtpCodeRepository } from './infrastructure/repositories/typeorm-otp-code.repository';
import { TypeOrmRefreshTokenRepository } from './infrastructure/repositories/refresh-token.repository';
import { OtpSenderService } from './infrastructure/services/otp-sender.service';
import {
  ACCESS_TOKEN_TTL_SECONDS,
  JwtService,
} from './infrastructure/services/jwt.service';
import { JwtAuthGuard } from './infrastructure/guards/jwt-auth.guard';
import { OtpIssuerService } from './application/services/otp-issuer.service';
import { TokenIssuerService } from './application/services/token-issuer.service';
import { RegisterUseCase } from './application/use-cases/register.use-case';
import { LoginUseCase } from './application/use-cases/login.use-case';
import { VerifyOtpUseCase } from './application/use-cases/verify-otp.use-case';
import { RefreshTokenUseCase } from './application/use-cases/refresh-token.use-case';
import { LogoutUseCase } from './application/use-cases/logout.use-case';
import { AuthController } from './infrastructure/controllers/auth.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([OtpCode, RefreshToken]),
    UsersModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: ACCESS_TOKEN_TTL_SECONDS },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    { provide: OtpCodeRepository, useClass: TypeOrmOtpCodeRepository },
    {
      provide: RefreshTokenRepository,
      useClass: TypeOrmRefreshTokenRepository,
    },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    OtpSenderService,
    OtpIssuerService,
    TokenIssuerService,
    JwtService,
    RegisterUseCase,
    LoginUseCase,
    VerifyOtpUseCase,
    RefreshTokenUseCase,
    LogoutUseCase,
  ],
})
export class AuthModule {}
