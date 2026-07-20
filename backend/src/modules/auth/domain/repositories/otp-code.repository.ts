export interface CreateOtpCodeData {
  identifier: string;
  codeHash: string;
  expiresAt: Date;
}

export abstract class OtpCodeRepository {
  abstract create(data: CreateOtpCodeData): Promise<void>;
}
