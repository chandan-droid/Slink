import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ------------------- AUTH -------------------

  Future<ApiResponse<AuthResponse>> login(String phoneNumber, String password) async {
    try {
      final loginRequest = LoginRequest(
        phoneNumber: phoneNumber,
        password: password,
      );

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginRequest.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        _authToken = authResponse.token;
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<AuthResponse>> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        _authToken = authResponse.token;
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // ------------------- USERS -------------------

  Future<ApiResponse<List<UserModel>>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.usersEndpoint}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final users = data.map((json) => UserModel.fromJson(json)).toList();
        return ApiResponse.success(users);
      } else {
        return ApiResponse.error('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<UserModel>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.currentUserEndpoint}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(UserModel.fromJson(data));
      } else {
        return ApiResponse.error('Failed to fetch current user: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // ------------------- CHAT -------------------

  /// Create or fetch an existing chat with recipientId
  Future<ApiResponse<String>> startChat(String recipientId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.startChatEndpoint}?recipientId=$recipientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data['chatId'] as String);
      } else {
        return ApiResponse.error('Failed to start chat: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Get all messages for a chat
  Future<ApiResponse<List<MessageModel>>> getChatHistory(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.chatHistoryEndpoint}/$chatId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final messages = data.map((json) => MessageModel.fromJson(json)).toList();
        return ApiResponse.success(messages);
      } else {
        return ApiResponse.error('Failed to fetch chat history: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Send a message (saves to database)
  Future<ApiResponse<MessageModel>> sendMessage(String chatId, String content) async {
    try {
      print('🌐 Sending message via REST API');
      print('   chatId: $chatId');
      print('   content: $content');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.sendMessageEndpoint}?chatId=$chatId&content=$content'),
        headers: _headers,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = MessageModel.fromJson(data);
        return ApiResponse.success(message);
      } else {
        return ApiResponse.error('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Mark a message as read
  Future<ApiResponse<void>> markMessageAsRead(String messageId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.markReadEndpoint}/$messageId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to mark message as read: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  void logout() {
    _authToken = null;
  }
}

// ------------------- API RESPONSE WRAPPER -------------------

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T data) => ApiResponse._(data: data, isSuccess: true);

  factory ApiResponse.error(String message) => ApiResponse._(error: message, isSuccess: false);
}
