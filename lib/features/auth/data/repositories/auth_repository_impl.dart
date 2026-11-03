import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/auth_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dio;
  final SecureStorage _storage;

  AuthRepositoryImpl(this._dio, this._storage);

  @override
  Future<AuthToken> login(String phoneNumber, String password) async {
    try {
      final res = await _dio.dio.post(
        AppConfig.loginEndpoint,
        data: LoginRequest(phoneNumber: phoneNumber, password: password).toJson(),
      );
      final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
      await _saveSession(auth);
      return _toToken(auth);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(message: NetworkException.parseError(e));
    }
  }

  @override
  Future<AuthToken> register({
    required String phoneNumber,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.dio.post(
        AppConfig.registerEndpoint,
        data: RegisterRequest(
          phoneNumber: phoneNumber,
          username: username,
          email: email,
          password: password,
        ).toJson(),
      );
      final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
      await _saveSession(auth);
      return _toToken(auth);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(message: NetworkException.parseError(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.dio.post('/api/auth/logout');
    } catch (_) {}
    await _storage.clearAll();
  }

  @override
  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  Future<void> _saveSession(AuthResponse auth) async {
    await _storage.saveToken(auth.token);
    await _storage.saveUserId(auth.userId);
    await _storage.saveUsername(auth.username);
  }

  AuthToken _toToken(AuthResponse auth) =>
      AuthToken(token: auth.token, userId: auth.userId, username: auth.username);
}

// ─── Provider ────────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(dioClientProvider), SecureStorage());
});
