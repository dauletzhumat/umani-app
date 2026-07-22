import type Redis from 'ioredis';
import { CategorizationService } from './categorization.service';
import { OpenAiClientService } from './openai-client.service';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import { Category } from '../../../categories/domain/entities/category.entity';

function fakeCategory(overrides: Partial<Category> = {}): Category {
  return {
    id: 'cat-1',
    userId: null,
    parentId: null,
    name: 'Продукты',
    icon: 'shopping_cart',
    createdAt: new Date(),
    deletedAt: null,
    ...overrides,
  };
}

describe('CategorizationService', () => {
  it('does not return a category when confidence is below 0.5', async () => {
    const redis = {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue('OK'),
    } as unknown as Redis;

    const openAiClient = {
      categorize: jest
        .fn()
        .mockResolvedValue({ categoryName: 'Продукты', confidence: 0.3 }),
    } as unknown as OpenAiClientService;

    const categoryRepository = {
      findAllForUser: jest.fn().mockResolvedValue([fakeCategory()]),
    } as unknown as CategoryRepository;

    const service = new CategorizationService(
      redis,
      openAiClient,
      categoryRepository,
    );

    const categoryId = await service.categorize({
      userId: 'user-1',
      merchant: 'Magnum',
      amount: '1500.00',
      currency: 'KZT',
    });

    expect(categoryId).toBeNull();
  });

  it('returns the matching categoryId when confidence is >= 0.5', async () => {
    const redis = {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue('OK'),
    } as unknown as Redis;

    const openAiClient = {
      categorize: jest
        .fn()
        .mockResolvedValue({ categoryName: 'Продукты', confidence: 0.9 }),
    } as unknown as OpenAiClientService;

    const categoryRepository = {
      findAllForUser: jest.fn().mockResolvedValue([fakeCategory()]),
    } as unknown as CategoryRepository;

    const service = new CategorizationService(
      redis,
      openAiClient,
      categoryRepository,
    );

    const categoryId = await service.categorize({
      userId: 'user-1',
      merchant: 'Magnum',
      amount: '1500.00',
      currency: 'KZT',
    });

    expect(categoryId).toBe('cat-1');
  });
});
