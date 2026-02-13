import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final WebSocketService _webSocketService = WebSocketService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> init() async {
    await _storageService.init();
    final token = _storageService.getAuthToken();
    if (token != null) {
      _apiService.setAuthToken(token);
      _isLoggedIn = true;
      await fetchCurrentUser();
    }
  }

  Future<bool> login(String phoneNumber, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(phoneNumber, password);

      if (response.isSuccess && response.data != null) {
        final authResponse = response.data!;
        await _storageService.saveAuthToken(authResponse.token);
        await _storageService.saveUsername(authResponse.username);
        _isLoggedIn = true;

        // Fetch current user info
        await fetchCurrentUser();

        // Connect WebSocket
        if (_currentUser != null) {
          _webSocketService.connect(
            authResponse.token,
            _currentUser!.id,
            _currentUser!.username,
          );
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        phoneNumber: phoneNumber,
        username: username,
        email: email,
        password: password,
      );

      final response = await _apiService.register(request);

      if (response.isSuccess && response.data != null) {
        final authResponse = response.data!;
        await _storageService.saveAuthToken(authResponse.token);
        await _storageService.saveUsername(authResponse.username);
        _isLoggedIn = true;

        // Fetch current user info
        await fetchCurrentUser();

        // Connect WebSocket
        if (_currentUser != null) {
          _webSocketService.connect(
            authResponse.token,
            _currentUser!.id,
            _currentUser!.username,
          );
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchCurrentUser() async {
    final response = await _apiService.getCurrentUser();
    if (response.isSuccess && response.data != null) {
      _currentUser = response.data;
      await _storageService.saveUserId(_currentUser!.id);
      await _storageService.saveUsername(_currentUser!.username);
      notifyListeners();
    }
  }

  Future<void> connectWebSocket() async {
    final token = _storageService.getAuthToken();
    if (token != null && _currentUser != null) {
      _webSocketService.connect(token, _currentUser!.id, _currentUser!.username);
    }
  }

  Future<void> logout() async {
    _webSocketService.disconnect();
    _apiService.logout();
    await _storageService.clearAll();
    _currentUser = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
