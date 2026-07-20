import { OtpCode } from '../entities/otp-code.entity';

export interface CreateOtpCodeData {
  identifier: string;
  codeHash: string;
  expiresAt: Date;
}

export abstract class OtpCodeRepository {
  abstract create(data: CreateOtpCodeData): Promise<void>;

  /** Most recent code issued for the identifier, regardless of used/expired state (ix_otp_codes_identifier). */
  abstract findLatestByIdentifier(identifier: string): Promise<OtpCode | null>;

  abstract incrementAttempts(id: string): Promise<void>;

  abstract markUsed(id: string): Promise<void>;
}
