import { Module } from '@nestjs/common';
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
import { OtpIssuerService } from './application/services/otp-issuer.service';
import { RegisterUseCase } from './application/use-cases/register.use-case';
import { LoginUseCase } from './application/use-cases/login.use-case';
import { VerifyOtpUseCase } from './application/use-cases/verify-otp.use-case';
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
    OtpSenderService,
    OtpIssuerService,
    JwtService,
    RegisterUseCase,
    LoginUseCase,
    VerifyOtpUseCase,
  ],
})
export class AuthModule {}
