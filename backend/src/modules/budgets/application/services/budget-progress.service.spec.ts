import { calculateProgressPercent } from './budget-progress.service';

describe('calculateProgressPercent', () => {
  it('is 0% when nothing has been spent', () => {
    expect(calculateProgressPercent('1000.00', '0')).toBe(0);
  });

  it('is 50% at half the limit', () => {
    expect(calculateProgressPercent('1000.00', '500.00')).toBe(50);
  });

  it('is 100% exactly at the limit', () => {
    expect(calculateProgressPercent('1000.00', '1000.00')).toBe(100);
  });

  it('goes above 100% on overspend instead of clamping', () => {
    expect(calculateProgressPercent('1000.00', '1500.00')).toBe(150);
  });

  it('floors a fractional percentage (docs/08_API.md §11 worked example)', () => {
    expect(calculateProgressPercent('80000.00', '56400.00')).toBe(70);
  });
});
