/**
 * JWT claims (docs/08_API.md §2). Lives in shared/ — every protected
 * controller across every module needs this shape via @CurrentUser(),
 * not just auth's own use-cases.
 */
export interface AccessTokenPayload {
  sub: string;
  scope: 'full' | 'guest';
  premiumStatus: string;
}
