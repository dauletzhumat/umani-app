import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  Future<void> register(String identifier) => _datasource.register(identifier);

  @override
  Future<void> login(String identifier) => _datasource.login(identifier);

  @override
  Future<VerifyOtpResult> verifyOtp(String identifier, String code) async {
    final json = await _datasource.verifyOtp(identifier, code);
    return VerifyOtpResult.fromJson(json);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider));
});
