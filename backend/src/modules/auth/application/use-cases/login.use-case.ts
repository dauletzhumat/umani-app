import { HttpStatus, Injectable } from '@nestjs/common';
import { UserRepository } from '../../../users/domain/repositories/user.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { parseIdentifier } from '../../../../shared/utils/identifier';
import { LoginDto } from '../../infrastructure/dto/login.dto';
import { IssuedOtp, OtpIssuerService } from '../services/otp-issuer.service';

@Injectable()
export class LoginUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly otpIssuerService: OtpIssuerService,
  ) {}

  async execute(dto: LoginDto): Promise<IssuedOtp> {
    const parsed = parseIdentifier(dto.identifier);
    if (!parsed) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'identifier must be a valid phone (+7...) or email',
        [{ field: 'identifier', issue: 'invalid_format' }],
      );
    }

    const existingUser =
      await this.userRepository.findActiveByIdentifier(parsed);
    if (!existingUser) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'No account is registered for this identifier',
      );
    }

    return this.otpIssuerService.issue(dto.identifier, parsed);
  }
}
