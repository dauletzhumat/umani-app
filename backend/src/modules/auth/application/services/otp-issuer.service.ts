import { Injectable } from '@nestjs/common';
import { randomInt } from 'crypto';
import * as bcrypt from 'bcryptjs';
import { OtpCodeRepository } from '../../domain/repositories/otp-code.repository';
import { OtpSenderService } from '../../infrastructure/services/otp-sender.service';
import { ParsedIdentifier } from '../../../../shared/utils/identifier';
import { maskIdentifier } from '../../../../shared/utils/mask-identifier';

const OTP_LENGTH_MIN = 100000;
const OTP_LENGTH_MAX = 1000000;
const OTP_TTL_SECONDS = 300;
const SALT_ROUNDS = 10;

export interface IssuedOtp {
  otpSentTo: string;
  expiresInSeconds: number;
}

/** Shared by register/login use-cases — generating, storing and sending an OTP is identical for both. */
@Injectable()
export class OtpIssuerService {
  constructor(
    private readonly otpCodeRepository: OtpCodeRepository,
    private readonly otpSenderService: OtpSenderService,
  ) {}

  async issue(
    rawIdentifier: string,
    parsedIdentifier: ParsedIdentifier,
  ): Promise<IssuedOtp> {
    const code = randomInt(OTP_LENGTH_MIN, OTP_LENGTH_MAX).toString();
    const codeHash = await bcrypt.hash(code, SALT_ROUNDS);
    const expiresAt = new Date(Date.now() + OTP_TTL_SECONDS * 1000);

    await this.otpCodeRepository.create({
      identifier: rawIdentifier,
      codeHash,
      expiresAt,
    });

    this.otpSenderService.send(rawIdentifier, code);

    return {
      otpSentTo: maskIdentifier(parsedIdentifier),
      expiresInSeconds: OTP_TTL_SECONDS,
    };
  }
}
