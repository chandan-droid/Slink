import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth Token
  Future<void> saveAuthToken(String token) async {
    await _prefs?.setString(AppConstants.tokenKey, token);
  }

  String? getAuthToken() {
    return _prefs?.getString(AppConstants.tokenKey);
  }

  Future<void> removeAuthToken() async {
    await _prefs?.remove(AppConstants.tokenKey);
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _prefs?.setString(AppConstants.userIdKey, userId);
  }

  String? getUserId() {
    return _prefs?.getString(AppConstants.userIdKey);
  }

  Future<void> removeUserId() async {
    await _prefs?.remove(AppConstants.userIdKey);
  }

  // Username
  Future<void> saveUsername(String username) async {
    await _prefs?.setString(AppConstants.usernameKey, username);
  }

  String? getUsername() {
    return _prefs?.getString(AppConstants.usernameKey);
  }

  Future<void> removeUsername() async {
    await _prefs?.remove(AppConstants.usernameKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return getAuthToken() != null;
  }
}

