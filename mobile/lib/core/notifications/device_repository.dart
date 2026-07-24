import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

enum DevicePlatform { ios, android }

String devicePlatformToString(DevicePlatform platform) {
  switch (platform) {
    case DevicePlatform.ios:
      return 'ios';
    case DevicePlatform.android:
      return 'android';
  }
}

/// POST /devices (docs/08_API.md §5.1) — idempotent registration, the
/// server upserts on (userId, fcmToken) so calling this on every app
/// start is safe.
abstract class DeviceRepository {
  Future<void> register({
    required String fcmToken,
    required DevicePlatform platform,
  });
}

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> register({
    required String fcmToken,
    required DevicePlatform platform,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/devices',
        data: {
          'fcmToken': fcmToken,
          'platform': devicePlatformToString(platform),
        },
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(ref.watch(apiClientProvider));
});
