import { HttpStatus, Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { randomUUID } from 'crypto';
import { UserRepository } from '../../../users/domain/repositories/user.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { parseIdentifier } from '../../../../shared/utils/identifier';
import { hashToken } from '../../../../shared/utils/hash-token';
import { VerifyOtpDto } from '../../infrastructure/dto/verify-otp.dto';
import { OtpCodeRepository } from '../../domain/repositories/otp-code.repository';
import { RefreshTokenRepository } from '../../domain/repositories/refresh-token.repository';
import { JwtService } from '../../infrastructure/services/jwt.service';

const MAX_OTP_ATTEMPTS = 5;
const REFRESH_TOKEN_TTL_SECONDS = 30 * 24 * 60 * 60;

export interface VerifyOtpResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: {
    id: string;
    phone: string | null;
    email: string | null;
    name: string | null;
    locale: string;
    defaultCurrency: string;
    isNewUser: boolean;
  };
}

@Injectable()
export class VerifyOtpUseCase {
  constructor(
    private readonly otpCodeRepository: OtpCodeRepository,
    private readonly userRepository: UserRepository,
    private readonly refreshTokenRepository: RefreshTokenRepository,
    private readonly jwtService: JwtService,
  ) {}

  async execute(dto: VerifyOtpDto): Promise<VerifyOtpResult> {
    const parsed = parseIdentifier(dto.identifier);
    if (!parsed) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'identifier must be a valid phone (+7...) or email',
        [{ field: 'identifier', issue: 'invalid_format' }],
      );
    }

    const otp = await this.otpCodeRepository.findLatestByIdentifier(
      dto.identifier,
    );
    if (!otp) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'OTP_INVALID',
        'No code was requested for this identifier',
      );
    }

    if (otp.attempts >= MAX_OTP_ATTEMPTS) {
      throw new AppException(
        HttpStatus.TOO_MANY_REQUESTS,
        'TOO_MANY_ATTEMPTS',
        'Too many incorrect attempts, request a new code',
      );
    }

    if (otp.usedAt) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'OTP_INVALID',
        'This code has already been used',
      );
    }

    if (otp.expiresAt.getTime() < Date.now()) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'OTP_EXPIRED',
        'Code has expired, request a new one',
      );
    }

    const isMatch = await bcrypt.compare(dto.code, otp.codeHash);
    if (!isMatch) {
      await this.otpCodeRepository.incrementAttempts(otp.id);
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'OTP_INVALID',
        'Invalid code',
      );
    }

    await this.otpCodeRepository.markUsed(otp.id);

    let user = await this.userRepository.findActiveByIdentifier(parsed);
    let isNewUser = false;
    if (!user) {
      user = await this.userRepository.create(parsed);
      isNewUser = true;
    }

    const { accessToken, expiresIn } = this.jwtService.signAccessToken({
      sub: user.id,
      scope: 'full',
      // No subscription table exists yet in the MVP schema — every user
      // starts on trial until Premium Infrastructure (Beta) lands.
      premiumStatus: 'trial',
    });

    const refreshToken = randomUUID();
    await this.refreshTokenRepository.create({
      userId: user.id,
      tokenHash: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_SECONDS * 1000),
    });

    return {
      accessToken,
      refreshToken,
      expiresIn,
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        name: user.name,
        locale: user.locale,
        defaultCurrency: user.defaultCurrency,
        isNewUser,
      },
    };
  }
}
