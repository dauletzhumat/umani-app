import { Inject, Injectable, Module, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export const REDIS_CLIENT = Symbol('REDIS_CLIENT');

/**
 * A plain ioredis client has no NestJS lifecycle hook of its own, so
 * app.close() would otherwise leave its connection (and reconnect timers)
 * open — this hangs the process indefinitely in tests (Jest waits for
 * the event loop to drain). This provider exists solely so Nest has
 * something implementing OnModuleDestroy to call .quit() through.
 */
@Injectable()
class RedisLifecycle implements OnModuleDestroy {
  constructor(@Inject(REDIS_CLIENT) private readonly client: Redis) {}

  async onModuleDestroy(): Promise<void> {
    await this.client.quit();
  }
}

/**
 * First use of Redis in the project (T4.4's categorization cache) —
 * docs/06_Architecture.md §15 lists several more planned uses (FX cache,
 * rate limiting, refresh-token denylist) that will import this module too.
 */
@Module({
  providers: [
    {
      provide: REDIS_CLIENT,
      inject: [ConfigService],
      useFactory: (configService: ConfigService) =>
        new Redis({
          host: configService.get<string>('REDIS_HOST'),
          port: configService.get<number>('REDIS_PORT'),
        }),
    },
    RedisLifecycle,
  ],
  exports: [REDIS_CLIENT],
})
export class RedisModule {}
