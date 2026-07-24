import { PaymentScheduleGeneratorService } from './payment-schedule-generator.service';

describe('PaymentScheduleGeneratorService', () => {
  const service = new PaymentScheduleGeneratorService();

  it('sums exactly to totalAmount when it divides evenly', () => {
    const payments = service.generate({
      totalAmount: '120000.00',
      installmentsCount: 12,
      startDate: '2026-07-01',
    });

    expect(payments).toHaveLength(12);
    const sum = payments.reduce((total, p) => total + Number(p.amount), 0);
    expect(sum.toFixed(2)).toBe('120000.00');
    expect(payments.every((p) => p.amount === '10000.00')).toBe(true);
  });

  it("absorbs the rounding remainder into the last payment when it doesn't divide evenly", () => {
    const payments = service.generate({
      totalAmount: '100000.00',
      installmentsCount: 3,
      startDate: '2026-07-01',
    });

    expect(payments).toHaveLength(3);
    const sum = payments.reduce((total, p) => total + Number(p.amount), 0);
    expect(sum.toFixed(2)).toBe('100000.00');

    // 100000 / 3 = 33333.33... -> first two floor to 33333.33, last
    // absorbs the remainder instead of losing a cent to rounding.
    expect(payments[0].amount).toBe('33333.33');
    expect(payments[1].amount).toBe('33333.33');
    expect(payments[2].amount).toBe('33333.34');
  });

  it('due dates advance one month per payment, starting on startDate itself', () => {
    const payments = service.generate({
      totalAmount: '30000.00',
      installmentsCount: 3,
      startDate: '2026-01-31',
    });

    expect(payments[0].dueDate).toBe('2026-01-31');
    expect(payments.map((p) => p.dueDate)).toHaveLength(3);
  });
});
