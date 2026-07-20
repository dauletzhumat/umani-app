/**
 * Approximates the masked shape shown in docs/08_API.md §2's example
 * ("+7 7** *** ** 12") — the doc gives one illustrative sample, not a
 * precise grouping algorithm, so this is a reasonable reading of it,
 * not a byte-exact spec.
 */
export function maskIdentifier(identifier: {
  phone: string | null;
  email: string | null;
}): string {
  if (identifier.phone) {
    return maskPhone(identifier.phone);
  }
  return maskEmail(identifier.email as string);
}

function maskPhone(phone: string): string {
  const countryCode = phone.slice(1, 2);
  const rest = phone.slice(2);
  const last2 = rest.slice(-2);
  const middle = rest.slice(0, -2);
  const maskedMiddle = middle.replace(/\d/g, (digit, index: number) =>
    index === 0 ? digit : '*',
  );
  const chunks = maskedMiddle.match(/.{1,3}/g) ?? [];

  return `+${countryCode} ${[...chunks, last2].join(' ')}`;
}

function maskEmail(email: string): string {
  const [localPart, domain] = email.split('@');
  const visible = localPart.slice(0, 1);
  return `${visible}${'*'.repeat(Math.max(localPart.length - 1, 1))}@${domain}`;
}
