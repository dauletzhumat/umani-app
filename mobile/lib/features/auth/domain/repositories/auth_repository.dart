/// Result of a successful POST /auth/otp/verify (docs/08_API.md §2).
/// Access token is intentionally not exposed beyond this call's caller —
/// it's short-lived and kept in memory only (T1.11 owns the full
/// token-management story).
class VerifyOtpResult {
  const VerifyOtpResult({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
  });

  final String accessToken;
  final String refreshToken;
  final bool isNewUser;

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return VerifyOtpResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isNewUser: user['isNewUser'] as bool,
    );
  }
}

abstract class AuthRepository {
  /// Sends an OTP for registration. Throws ApiException(USER_ALREADY_EXISTS)
  /// if the identifier is already registered.
  Future<void> register(String identifier);

  /// Sends an OTP for login. Throws ApiException(NOT_FOUND) if no account
  /// exists for the identifier.
  Future<void> login(String identifier);

  Future<VerifyOtpResult> verifyOtp(String identifier, String code);
}
