/// Central configuration — swap baseUrl per environment.
class AppConfig {
  static const String baseUrl = 'https://noncurious-contracted-elena.ngrok-free.dev';
  static const String wsUrl = 'https://noncurious-contracted-elena.ngrok-free.dev/ws';

  // REST endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String usersEndpoint = '/api/users';
  static const String currentUserEndpoint = '/api/users/me';
  static const String startChatEndpoint = '/api/chat/start';
  static const String communitiesEndpoint = '/api/communities';
  static const String startCommunityChatEndpoint = '/api/chat/community/start';
  static const String chatHistoryEndpoint = '/api/messages/history';
  static const String markReadEndpoint = '/api/messages/mark-read';
  static const String notificationsEndpoint = '/api/notifications';
  static const String notificationsCountEndpoint = '/api/notifications/count';
  static const String notificationsMarkAllRead = '/api/notifications/mark-all-read';
  static const String devicesEndpoint = '/api/users/devices';

  // WebSocket destinations
  static const String wsAddUser = '/app/chat.addUser';
  static const String wsSendMessage = '/app/chat.sendMessage';
  static const String wsMarkRead = '/app/chat.markRead';
  static const String wsTyping = '/app/chat.typing';
  static const String wsMessagesQueue = '/user/queue/messages';
  static const String wsTypingQueue = '/user/queue/typing';
  static const String wsReceiptsQueue = '/user/queue/receipts';
  static const String wsNotificationsQueue = '/user/queue/notifications';
  static const String wsStatusTopic = '/topic/user.status';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String fcmTokenKey = 'fcm_device_token';

  // App
  static const String appName = 'Slink';
  static const String appVersion = '1.0.0';

  // Timeouts (ms)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int typingTimeoutMs = 3000;

  /// DEV ONLY — paste a valid JWT here to skip SecureStorage during testing.
  /// Leave as empty string for the normal auth flow.
  static const String devToken = '';
}
