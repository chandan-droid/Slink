import '../entities/auth_token.dart';

abstract class AuthRepository {
  Future<AuthToken> login(String phoneNumber, String password);
  Future<AuthToken> register({
    required String phoneNumber,
    required String username,
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<bool> isLoggedIn();
}

