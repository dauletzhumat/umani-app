import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/access_token_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

/// docs/04_User_Flows.md §3, Экран 4 — "Продолжить как гость". No
/// refresh token, nothing written to SessionStorage: a guest session is
/// device-local only and doesn't survive a cold start (by design, see
/// AuthRepository.startGuestSession).
class StartGuestSession {
  const StartGuestSession(this._authRepository, this._accessTokenNotifier);

  final AuthRepository _authRepository;
  final AccessTokenNotifier _accessTokenNotifier;

  Future<void> call() async {
    final accessToken = await _authRepository.startGuestSession();
    _accessTokenNotifier.set(accessToken);
  }
}

final startGuestSessionProvider = Provider<StartGuestSession>((ref) {
  return StartGuestSession(
    ref.watch(authRepositoryProvider),
    ref.watch(accessTokenProvider.notifier),
  );
});
