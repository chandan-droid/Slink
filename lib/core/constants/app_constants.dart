// App-wide constants
class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8082'; // For Android emulator
  static const String wsUrl = 'ws://localhost:8082/ws';

  // For physical device, use your computer's IP:
  // static const String baseUrl = 'http://192.168.1.x:8082';
  // static const String wsUrl = 'ws://192.168.1.x:8082/ws';

  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String usersEndpoint = '/api/auth/users';
  static const String currentUserEndpoint = '/api/chat/current-user';
  static const String chatHistoryEndpoint = '/api/chat/history';
  static const String startChatEndpoint = '/api/chat/start';
  static const String sendMessageEndpoint = '/api/chat/send';
  static const String markReadEndpoint = '/api/chat/mark-read';

  // WebSocket Destinations
  static const String wsMessagesQueue = '/user/queue/messages';
  static const String wsTypingQueue = '/user/queue/typing';
  static const String wsStatusTopic = '/topic/user.status';
  static const String wsSendMessage = '/app/chat.sendMessage';
  static const String wsTyping = '/app/chat.typing';
  static const String wsAddUser = '/app/chat.addUser';
  static const String wsMarkRead = '/app/chat.markRead';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';

  // App Info
  static const String appName = 'Slink';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Typing indicator timeout
  static const int typingTimeoutMs = 3000;
}
