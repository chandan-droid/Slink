import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/websocket/stomp_service.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../features/notification/data/repositories/device_repository.dart';
import '../../../../core/utils/logger.dart';

// ─── State ───────────────────────────────────────────────────────────────────
class AuthState {
  final AuthToken? token;
  final bool isLoading;
  final String? error;

  const AuthState({this.token, this.isLoading = false, this.error});

  bool get isLoggedIn => token != null;

  AuthState copyWith({AuthToken? token, bool? isLoading, String? error}) =>
      AuthState(
        token: token ?? this.token,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final SecureStorage _storage;
  final SlinkStompService _stomp;
  final PushNotificationService _push;
  final DeviceRepository _deviceRepo;

  AuthNotifier(
    this._repo,
    this._storage,
    this._stomp,
    this._push,
    this._deviceRepo,
  ) : super(const AuthState()) {
    init();
  }

  /// Called once on app start — restores session from secure storage.
  Future<void> init() async {
    AppLogger.info('Auth: Checking for existing user session...', tag: 'Auth');
    final token = await _storage.getToken();
    if (token != null) {
      final userId = await _storage.getUserId() ?? '';
      final username = await _storage.getUsername() ?? '';
      AppLogger.info('Auth: Session found for $username ($userId)', tag: 'Auth');
      final authToken = AuthToken(token: token, userId: userId, username: username);
      state = state.copyWith(token: authToken);
      _connectWs(authToken);
      _registerPushToken();
    } else {
      AppLogger.info('Auth: No existing user session found', tag: 'Auth');
    }
  }

  Future<bool> login(String phone, String password) async {
    AppLogger.info('Auth: Login requested for phone = $phone', tag: 'Auth');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repo.login(phone, password);
      AppLogger.info('Auth: Login successful for ${token.username} (${token.userId})', tag: 'Auth');
      state = state.copyWith(token: token, isLoading: false);
      _connectWs(token);
      _registerPushToken();
      return true;
    } catch (e, st) {
      AppLogger.error('Auth: Login failed for phone = $phone', tag: 'Auth', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String phone,
    required String username,
    required String email,
    required String password,
  }) async {
    AppLogger.info('Auth: Registration requested for $username ($email, $phone)', tag: 'Auth');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repo.register(
        phoneNumber: phone,
        username: username,
        email: email,
        password: password,
      );
      AppLogger.info('Auth: Registration successful for ${token.username} (${token.userId})', tag: 'Auth');
      state = state.copyWith(token: token, isLoading: false);
      _connectWs(token);
      _registerPushToken();
      return true;
    } catch (e, st) {
      AppLogger.error('Auth: Registration failed for $username', tag: 'Auth', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    AppLogger.info('Auth: Logout requested', tag: 'Auth');
    await _push.unregisterFromBackend(_deviceRepo);
    _stomp.disconnect();
    await _repo.logout();
    state = const AuthState();
    AppLogger.info('Auth: Logout completed successfully', tag: 'Auth');
  }

  void clearError() => state = state.copyWith(error: null);

  void _connectWs(AuthToken t) {
    if (!_stomp.isConnected) {
      AppLogger.info('Auth: Initializing WebSocket connection for ${t.username}', tag: 'Auth');
      _stomp.connect(token: t.token, userId: t.userId, username: t.username);
    }
  }

  void _registerPushToken() {
    _push.registerWithBackend(_deviceRepo);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    SecureStorage(),
    ref.read(stompServiceProvider),
    PushNotificationService.instance,
    ref.read(deviceRepositoryProvider),
  );
});

/// Convenience — current authenticated user ID (empty when logged out).
final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider).token?.userId ?? '';
});

/// Current username
final currentUsernameProvider = Provider<String>((ref) {
  return ref.watch(authProvider).token?.username ?? '';
});
