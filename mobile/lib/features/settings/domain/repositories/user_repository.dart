import '../entities/user_profile.dart';

abstract class UserRepository {
  /// GET /users/me (docs/08_API.md §12).
  Future<UserProfile> fetchProfile();

  /// PATCH /users/me (docs/08_API.md §12).
  Future<UserProfile> updateProfile({String? name, String? defaultCurrency});

  /// DELETE /users/me (docs/08_API.md §12, T10.1) — returns the ISO-8601
  /// date the account will actually be purged.
  Future<String> deleteAccount();
}
