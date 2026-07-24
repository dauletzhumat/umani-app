import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_repository.dart';

/// Isolates the one call that touches the real Firebase SDK so
/// [PushService] stays unit-testable without Firebase.initializeApp() —
/// no Firebase project exists in this environment, same shape as
/// ReceiptCaptureService's camera abstraction from T4.8.
abstract class FcmTokenSource {
  Future<String?> getToken();
}

class FirebaseFcmTokenSource implements FcmTokenSource {
  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}

/// Registers the device's FCM token on the backend and exposes incoming
/// foreground pushes (T5.2, docs/Development_Tasks.md).
class PushService {
  PushService(this._deviceRepository, [FcmTokenSource? tokenSource])
    : _tokenSource = tokenSource ?? FirebaseFcmTokenSource();

  final DeviceRepository _deviceRepository;
  final FcmTokenSource _tokenSource;

  /// No-ops on web — there's no FCM web setup (VAPID key, service
  /// worker) in this project, and `dart:io`'s Platform throws there.
  Future<void> registerDevice() async {
    if (kIsWeb) return;

    final token = await _tokenSource.getToken();
    if (token == null) return;

    await _deviceRepository.register(
      fcmToken: token,
      platform: Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
    );
  }

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
}

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref.watch(deviceRepositoryProvider));
});
