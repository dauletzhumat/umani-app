import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  App,
  cert,
  deleteApp,
  initializeApp,
  ServiceAccount,
} from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Thin wrapper around firebase-admin so a missing service account degrades
 * to "push skipped" rather than throwing — there's no real Firebase
 * project in this environment (dev sandbox), same graceful-degradation
 * shape as OpenAiClientService/VisionService.
 */
@Injectable()
export class FcmService implements OnModuleDestroy {
  private readonly logger = new Logger(FcmService.name);
  private readonly app: App | null;

  constructor(configService: ConfigService) {
    const serviceAccountJson = configService.get<string>(
      'FIREBASE_SERVICE_ACCOUNT_JSON',
    );
    if (!serviceAccountJson) {
      this.app = null;
      return;
    }

    try {
      const serviceAccount = JSON.parse(serviceAccountJson) as ServiceAccount;
      this.app = initializeApp({ credential: cert(serviceAccount) });
    } catch {
      this.logger.warn('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON');
      this.app = null;
    }
  }

  async onModuleDestroy(): Promise<void> {
    if (this.app) await deleteApp(this.app);
  }

  /** Sends to a single device token. Returns false (never throws) on a
   * missing config or a delivery failure — an invalid/unregistered token
   * shouldn't fail the notification that's already been persisted. */
  async send(token: string, payload: PushPayload): Promise<boolean> {
    if (!this.app) return false;

    try {
      await getMessaging(this.app).send({
        token,
        notification: { title: payload.title, body: payload.body },
        data: payload.data,
      });
      return true;
    } catch (error) {
      this.logger.warn(`FCM send failed: ${(error as Error).message}`);
      return false;
    }
  }
}
