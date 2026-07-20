import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OtpCode } from '../../domain/entities/otp-code.entity';
import {
  CreateOtpCodeData,
  OtpCodeRepository,
} from '../../domain/repositories/otp-code.repository';

@Injectable()
export class TypeOrmOtpCodeRepository implements OtpCodeRepository {
  constructor(
    @InjectRepository(OtpCode)
    private readonly repository: Repository<OtpCode>,
  ) {}

  async create(data: CreateOtpCodeData): Promise<void> {
    await this.repository.insert({
      identifier: data.identifier,
      codeHash: data.codeHash,
      expiresAt: data.expiresAt,
    });
  }
}
