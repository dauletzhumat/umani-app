import { HttpStatus, Injectable } from '@nestjs/common';
import { UserRepository } from '../../../users/domain/repositories/user.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { parseIdentifier } from '../../../../shared/utils/identifier';
import { RegisterDto } from '../../infrastructure/dto/register.dto';
import { IssuedOtp, OtpIssuerService } from '../services/otp-issuer.service';

@Injectable()
export class RegisterUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly otpIssuerService: OtpIssuerService,
  ) {}

  async execute(dto: RegisterDto): Promise<IssuedOtp> {
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
    if (existingUser) {
      throw new AppException(
        HttpStatus.CONFLICT,
        'USER_ALREADY_EXISTS',
        'A user with this identifier is already registered',
      );
    }

    return this.otpIssuerService.issue(dto.identifier, parsed);
  }
}
