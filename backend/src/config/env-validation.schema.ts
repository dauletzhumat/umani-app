import * as Joi from 'joi';

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),
  PORT: Joi.number().port().default(3000),

  POSTGRES_HOST: Joi.string().default('localhost'),
  POSTGRES_PORT: Joi.number().port().default(5432),
  POSTGRES_USER: Joi.string().default('ai_finance'),
  POSTGRES_PASSWORD: Joi.string().default('ai_finance'),
  POSTGRES_DB: Joi.string().default('ai_finance'),

  // Dev-only default — staging/production must override this (DevOps task, not MVP scope).
  JWT_SECRET: Joi.string().default('dev-only-insecure-secret-change-me'),

  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().port().default(6379),

  // Optional: no key configured means AI categorization is a no-op
  // (CategorizationService degrades to "no category"), same shape as
  // OtpSenderService's "no provider chosen yet" stub from T1.2.
  OPENAI_API_KEY: Joi.string().allow('').default(''),
});
