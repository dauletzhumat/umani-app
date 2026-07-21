import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory only — per docs/08_API.md §2 the access token is never
/// persisted to disk (short-lived, kept in memory by design). Full
/// auto-refresh wiring (attaching it to requests, rotating on 401) is
/// T1.11's job; this is just a holder so a freshly issued token isn't
/// thrown away after verify.
class AccessTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String token) => state = token;

  void clear() => state = null;
}

final accessTokenProvider = NotifierProvider<AccessTokenNotifier, String?>(
  AccessTokenNotifier.new,
);
