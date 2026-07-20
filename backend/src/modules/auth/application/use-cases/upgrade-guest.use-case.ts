import { HttpStatus, Injectable } from '@nestjs/common';
import { UserRepository } from '../../../users/domain/repositories/user.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { parseIdentifier } from '../../../../shared/utils/identifier';
import { VerifyOtpDto } from '../../infrastructure/dto/verify-otp.dto';
import { OtpVerifierService } from '../services/otp-verifier.service';
import { TokenIssuerService } from '../services/token-issuer.service';
import { VerifyOtpResult } from './verify-otp.use-case';

@Injectable()
export class UpgradeGuestUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly otpVerifierService: OtpVerifierService,
    private readonly tokenIssuerService: TokenIssuerService,
  ) {}

  async execute(
    guestUserId: string,
    dto: VerifyOtpDto,
  ): Promise<VerifyOtpResult> {
    const parsed = parseIdentifier(dto.identifier);
    if (!parsed) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'identifier must be a valid phone (+7...) or email',
        [{ field: 'identifier', issue: 'invalid_format' }],
      );
    }

    const alreadyUpgraded = await this.userRepository.findById(guestUserId);
    if (alreadyUpgraded) {
      throw new AppException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'This session has already been upgraded',
      );
    }

    const existingUser =
      await this.userRepository.findActiveByIdentifier(parsed);
    if (existingUser) {
      throw new AppException(
        HttpStatus.CONFLICT,
        'USER_ALREADY_EXISTS',
        'A user with this identifier is already registered',
      );
    }

    await this.otpVerifierService.verify(dto.identifier, dto.code);

    const user = await this.userRepository.createWithId(guestUserId, parsed);

    const { accessToken, refreshToken, expiresIn } =
      await this.tokenIssuerService.issue(user.id);

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
        isNewUser: true,
      },
    };
  }
}
