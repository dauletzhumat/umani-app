/**
 * Same Prompt-Registry-shaped static object as categorize.prompt.ts
 * (T4.4) — see that file's comment for why this isn't the full DB-backed
 * registry from docs/10_AI.md §9.
 */
export const PARSE_RECEIPT_PROMPT = {
  key: 'ocr.parse-receipt',
  version: 1,
  model: 'gpt-4o-mini',
  temperature: 0.2,
  maxOutputTokens: 500,
  template: `Тебе дан сырой текст, распознанный с чека в Казахстане (может быть на русском или казахском, суммы в тенге). Извлеки структуру. Если поле не удаётся определить надёжно — верни null, не угадывай.

Верни строго JSON по схеме:
{
  "merchant": string | null,
  "totalAmount": string | null,
  "currency": "KZT",
  "date": "YYYY-MM-DD" | null,
  "lineItems": [ { "name": string, "price": string } ]
}

Текст чека:
"""
{ocrRawText}
"""`,
  outputSchema: {
    type: 'object',
    properties: {
      merchant: { type: ['string', 'null'] },
      totalAmount: { type: ['string', 'null'] },
      currency: { type: 'string' },
      date: { type: ['string', 'null'] },
      lineItems: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            name: { type: 'string' },
            price: { type: 'string' },
          },
          required: ['name', 'price'],
        },
      },
    },
    required: ['merchant', 'totalAmount', 'currency', 'date', 'lineItems'],
    additionalProperties: false,
  },
} as const;

export function buildParseReceiptPrompt(ocrRawText: string): string {
  return PARSE_RECEIPT_PROMPT.template.replace('{ocrRawText}', ocrRawText);
}
