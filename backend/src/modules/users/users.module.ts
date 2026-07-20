import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './domain/entities/user.entity';
import { UserRepository } from './domain/repositories/user.repository';
import { TypeOrmUserRepository } from './infrastructure/repositories/typeorm-user.repository';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [{ provide: UserRepository, useClass: TypeOrmUserRepository }],
  exports: [UserRepository],
})
export class UsersModule {}
