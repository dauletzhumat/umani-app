// Mirrors the users table's chk_users_phone_format / chk_users_email_format
// (docs/07_Database.md §5.1) so a value accepted here is always insertable.
const PHONE_REGEX = /^\+[1-9][0-9]{7,14}$/;
const EMAIL_REGEX = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export interface ParsedIdentifier {
  phone: string | null;
  email: string | null;
}

/** Returns null when the identifier matches neither a phone nor an email format. */
export function parseIdentifier(identifier: string): ParsedIdentifier | null {
  if (PHONE_REGEX.test(identifier)) {
    return { phone: identifier, email: null };
  }
  if (EMAIL_REGEX.test(identifier)) {
    return { phone: null, email: identifier.toLowerCase() };
  }
  return null;
}
