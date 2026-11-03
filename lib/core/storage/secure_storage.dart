import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

/// Wraps flutter_secure_storage for JWT / user info persistence.
class SecureStorage {
  SecureStorage._();
  static final SecureStorage _instance = SecureStorage._();
  factory SecureStorage() => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Token ──────────────────────────────────────────────────────
  Future<void> saveToken(String token) {
    AppLogger.debug('SecureStorage: Writing token', tag: 'Storage');
    return _storage.write(key: AppConfig.tokenKey, value: token);
  }

  Future<String?> getToken() {
    AppLogger.debug('SecureStorage: Reading token', tag: 'Storage');
    return _storage.read(key: AppConfig.tokenKey);
  }

  Future<void> deleteToken() {
    AppLogger.debug('SecureStorage: Deleting token', tag: 'Storage');
    return _storage.delete(key: AppConfig.tokenKey);
  }

  // ─── User ID ────────────────────────────────────────────────────
  Future<void> saveUserId(String id) {
    AppLogger.debug('SecureStorage: Writing userId ($id)', tag: 'Storage');
    return _storage.write(key: AppConfig.userIdKey, value: id);
  }

  Future<String?> getUserId() {
    AppLogger.debug('SecureStorage: Reading userId', tag: 'Storage');
    return _storage.read(key: AppConfig.userIdKey);
  }

  // ─── Username ───────────────────────────────────────────────────
  Future<void> saveUsername(String name) {
    AppLogger.debug('SecureStorage: Writing username ($name)', tag: 'Storage');
    return _storage.write(key: AppConfig.usernameKey, value: name);
  }

  Future<String?> getUsername() {
    AppLogger.debug('SecureStorage: Reading username', tag: 'Storage');
    return _storage.read(key: AppConfig.usernameKey);
  }

  // ─── FCM Device Token ───────────────────────────────────────────
  Future<void> saveFcmToken(String token) {
    AppLogger.debug('SecureStorage: Writing FCM token', tag: 'Storage');
    return _storage.write(key: AppConfig.fcmTokenKey, value: token);
  }

  Future<String?> getFcmToken() {
    AppLogger.debug('SecureStorage: Reading FCM token', tag: 'Storage');
    return _storage.read(key: AppConfig.fcmTokenKey);
  }

  Future<void> deleteFcmToken() {
    AppLogger.debug('SecureStorage: Deleting FCM token', tag: 'Storage');
    return _storage.delete(key: AppConfig.fcmTokenKey);
  }

  // ─── Clear all ──────────────────────────────────────────────────
  Future<void> clearAll() {
    AppLogger.info('SecureStorage: Clearing all data', tag: 'Storage');
    return _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final loggedIn = token != null;
    AppLogger.debug('SecureStorage: Check logged in ($loggedIn)', tag: 'Storage');
    return loggedIn;
  }
}
