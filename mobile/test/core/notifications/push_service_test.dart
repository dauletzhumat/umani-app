import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/notifications/device_repository.dart';
import 'package:mobile/core/notifications/push_service.dart';

class _FakeDeviceRepository implements DeviceRepository {
  String? lastFcmToken;
  DevicePlatform? lastPlatform;
  int registerCallCount = 0;

  @override
  Future<void> register({
    required String fcmToken,
    required DevicePlatform platform,
  }) async {
    registerCallCount++;
    lastFcmToken = fcmToken;
    lastPlatform = platform;
  }
}

class _FakeFcmTokenSource implements FcmTokenSource {
  _FakeFcmTokenSource(this.token);

  final String? token;

  @override
  Future<String?> getToken() async => token;
}

void main() {
  test(
    'registerDevice() registers the FCM token on the backend on first launch',
    () async {
      final deviceRepository = _FakeDeviceRepository();
      final pushService = PushService(
        deviceRepository,
        _FakeFcmTokenSource('fcm-token-123'),
      );

      await pushService.registerDevice();

      expect(deviceRepository.registerCallCount, 1);
      expect(deviceRepository.lastFcmToken, 'fcm-token-123');
    },
  );

  test('a null token (permission denied / not yet available) skips registration', () async {
    final deviceRepository = _FakeDeviceRepository();
    final pushService = PushService(deviceRepository, _FakeFcmTokenSource(null));

    await pushService.registerDevice();

    expect(deviceRepository.registerCallCount, 0);
  });
}
