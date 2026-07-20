import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { RegisterUseCase } from '../../application/use-cases/register.use-case';
import { LoginUseCase } from '../../application/use-cases/login.use-case';
import { VerifyOtpUseCase } from '../../application/use-cases/verify-otp.use-case';
import { RefreshTokenUseCase } from '../../application/use-cases/refresh-token.use-case';
import { LogoutUseCase } from '../../application/use-cases/logout.use-case';
import { GuestSessionUseCase } from '../../application/use-cases/guest-session.use-case';
import { UpgradeGuestUseCase } from '../../application/use-cases/upgrade-guest.use-case';
import { RegisterDto } from '../dto/register.dto';
import { LoginDto } from '../dto/login.dto';
import { VerifyOtpDto } from '../dto/verify-otp.dto';
import { RefreshTokenDto } from '../dto/refresh-token.dto';
import { LogoutDto } from '../dto/logout.dto';
import { Public } from '../../../../shared/decorators/public.decorator';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import { AppException } from '../../../../shared/exceptions/app.exception';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly registerUseCase: RegisterUseCase,
    private readonly loginUseCase: LoginUseCase,
    private readonly verifyOtpUseCase: VerifyOtpUseCase,
    private readonly refreshTokenUseCase: RefreshTokenUseCase,
    private readonly logoutUseCase: LogoutUseCase,
    private readonly guestSessionUseCase: GuestSessionUseCase,
    private readonly upgradeGuestUseCase: UpgradeGuestUseCase,
  ) {}

  @Public()
  @Post('register')
  @HttpCode(HttpStatus.ACCEPTED)
  register(@Body() dto: RegisterDto) {
    return this.registerUseCase.execute(dto);
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.ACCEPTED)
  login(@Body() dto: LoginDto) {
    return this.loginUseCase.execute(dto);
  }

  @Public()
  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.verifyOtpUseCase.execute(dto);
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshTokenDto) {
    return this.refreshTokenUseCase.execute(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: LogoutDto,
  ): Promise<void> {
    await this.logoutUseCase.logout(user.sub, dto.refreshToken);
  }

  @Post('logout-all')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logoutAll(@CurrentUser() user: AccessTokenPayload): Promise<void> {
    await this.logoutUseCase.logoutAll(user.sub);
  }

  @Public()
  @Post('guest')
  @HttpCode(HttpStatus.OK)
  guest() {
    return this.guestSessionUseCase.execute();
  }

  @Post('guest/upgrade')
  @HttpCode(HttpStatus.OK)
  upgradeGuest(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: VerifyOtpDto,
  ) {
    if (user.scope !== 'guest') {
      throw new AppException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN_ROLE',
        'Only guest sessions can be upgraded',
      );
    }
    return this.upgradeGuestUseCase.execute(user.sub, dto);
  }
}
