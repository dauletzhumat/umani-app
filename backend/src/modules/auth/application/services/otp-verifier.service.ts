import { HttpStatus, Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { OtpCodeRepository } from '../../domain/repositories/otp-code.repository';

const MAX_OTP_ATTEMPTS = 5;

/** Shared by verify-otp and guest-upgrade use-cases — checking a submitted code against the stored one is identical for both. */
@Injectable()
export class OtpVerifierService {
  constructor(private readonly otpCodeRepository: OtpCodeRepository) {}

  async verify(identifier: string, code: string): Promise<void> {
    const otp = await this.otpCodeRepository.findLatestByIdentifier(identifier);
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

    const isMatch = await bcrypt.compare(code, otp.codeHash);
    if (!isMatch) {
      await this.otpCodeRepository.incrementAttempts(otp.id);
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'OTP_INVALID',
        'Invalid code',
      );
    }

    await this.otpCodeRepository.markUsed(otp.id);
  }
}
