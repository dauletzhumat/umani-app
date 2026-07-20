import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { OtpCode } from './domain/entities/otp-code.entity';
import { OtpCodeRepository } from './domain/repositories/otp-code.repository';
import { TypeOrmOtpCodeRepository } from './infrastructure/repositories/typeorm-otp-code.repository';
import { OtpSenderService } from './infrastructure/services/otp-sender.service';
import { OtpIssuerService } from './application/services/otp-issuer.service';
import { RegisterUseCase } from './application/use-cases/register.use-case';
import { LoginUseCase } from './application/use-cases/login.use-case';
import { AuthController } from './infrastructure/controllers/auth.controller';

@Module({
  imports: [TypeOrmModule.forFeature([OtpCode]), UsersModule],
  controllers: [AuthController],
  providers: [
    { provide: OtpCodeRepository, useClass: TypeOrmOtpCodeRepository },
    OtpSenderService,
    OtpIssuerService,
    RegisterUseCase,
    LoginUseCase,
  ],
})
export class AuthModule {}
