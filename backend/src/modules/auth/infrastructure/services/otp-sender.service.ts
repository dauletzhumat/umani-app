import { Injectable, Logger } from '@nestjs/common';

/**
 * Stub — no SMS/email provider is chosen in the docs yet
 * (Development_Tasks.md T1.2 explicitly scopes this as a stub).
 * Swap the body for a real provider client once one is picked.
 */
@Injectable()
export class OtpSenderService {
  private readonly logger = new Logger(OtpSenderService.name);

  send(identifier: string, code: string): void {
    this.logger.log(`OTP for ${identifier}: ${code}`);
  }
}
