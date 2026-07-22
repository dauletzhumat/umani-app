/**
 * A single static prompt, shaped like a Prompt Registry record
 * (docs/10_AI.md §9's key/version/template/model/temperature/outputSchema
 * fields) without the DB-backed dynamic registry itself — that's a
 * separate, larger infra task (10_AI.md §15, item 1), not part of T4.4.
 */
export const CATEGORIZE_PROMPT = {
  key: 'transaction.categorize',
  version: 1,
  model: 'gpt-4o-mini',
  temperature: 0.3,
  maxOutputTokens: 100,
  template: `Ты категоризируешь финансовые транзакции для приложения личных финансов в Казахстане.
Не выдумывай категории, которых нет в списке ниже. Если не уверен — верни низкий confidence, а не угадывай.

Доступные категории: {categoryNames}

Примеры категоризации для Казахстана:
- "Magnum", "Small", "Galmart" → Продукты
- "Yandex Go", "InDrive" → Транспорт
- "Chocofamily", "Kaspi Магазин" → зависит от товара, если неясно — Прочее

Мерчант/описание: "{merchant}", сумма: {amount} {currency}.
Не выдумывай сумму или мерчанта — используй только переданные значения.

Верни JSON: { "categoryName": string, "confidence": number от 0 до 1 }`,
  outputSchema: {
    type: 'object',
    properties: {
      categoryName: { type: 'string' },
      confidence: { type: 'number' },
    },
    required: ['categoryName', 'confidence'],
    additionalProperties: false,
  },
} as const;

export function buildCategorizePrompt(params: {
  merchant: string;
  amount: string;
  currency: string;
  categoryNames: string[];
}): string {
  return CATEGORIZE_PROMPT.template
    .replace('{categoryNames}', params.categoryNames.join(', '))
    .replace('{merchant}', params.merchant)
    .replace('{amount}', params.amount)
    .replace('{currency}', params.currency);
}
