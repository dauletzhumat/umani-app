import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Isolates the real Firebase SDK call — see [FcmTokenSource] in
/// push_service.dart for why this needs to be swappable.
abstract class NotificationPermissionRequester {
  Future<bool> requestPermission();
}

class FirebaseNotificationPermissionRequester
    implements NotificationPermissionRequester {
  @override
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}

/// Requests notification permission — iOS's explicit prompt and
/// Android 13+'s runtime permission are both covered by
/// FirebaseMessaging.requestPermission() (T5.2,
/// docs/Development_Tasks.md).
class NotificationPermissionHandler {
  NotificationPermissionHandler([NotificationPermissionRequester? requester])
    : _requester = requester ?? FirebaseNotificationPermissionRequester();

  final NotificationPermissionRequester _requester;

  /// No-ops on web — push isn't set up there (see PushService.registerDevice).
  Future<bool> requestPermission() {
    if (kIsWeb) return Future.value(false);
    return _requester.requestPermission();
  }
}

final notificationPermissionHandlerProvider =
    Provider<NotificationPermissionHandler>((ref) {
      return NotificationPermissionHandler();
    });
