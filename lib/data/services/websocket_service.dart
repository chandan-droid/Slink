import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  String? _authToken;
  String? _currentUserId;
  String? _currentUsername;

  // Stream controllers for different events
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<ChatMessage>.broadcast();
  final _statusController = StreamController<UserStatus>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Public streams
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<ChatMessage> get typingStream => _typingController.stream;
  Stream<UserStatus> get statusStream => _statusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _stompClient?.connected ?? false;

  void connect(String token, String userId, String username) {
    _authToken = token;
    _currentUserId = userId;
    _currentUsername = username;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '${AppConstants.baseUrl}/ws',
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: (error) {
          print('WebSocket Error: $error');
          _connectionController.add(false);
        },
        onStompError: (frame) {
          print('STOMP Error: ${frame.body}');
          _connectionController.add(false);
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    print('✅ WebSocket connected successfully');
    print('👤 Current User ID: $_currentUserId');
    _connectionController.add(true);

    // Subscribe to personal messages
    print('📥 Subscribing to: ${AppConstants.wsMessagesQueue}');
    _stompClient!.subscribe(
      destination: AppConstants.wsMessagesQueue,
      callback: (frame) {
        print('📬 Raw message received: ${frame.body}');
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            print('📦 Parsed message data: $data');
            final message = ChatMessage.fromJson(data);
            print('✉️ ChatMessage created: ${message.content} from ${message.senderId}');
            _messageController.add(message);
          } catch (e) {
            print('❌ Error parsing message: $e');
          }
        }
      },
    );

    // Subscribe to typing notifications
    print('📥 Subscribing to: ${AppConstants.wsTypingQueue}');
    _stompClient!.subscribe(
      destination: AppConstants.wsTypingQueue,
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            print('⌨️ Typing notification received: $data');
            final typingMessage = ChatMessage.fromJson(data);
            _typingController.add(typingMessage);
          } catch (e) {
            print('❌ Error parsing typing notification: $e');
          }
        }
      },
    );

    // Subscribe to user status updates
    print('📥 Subscribing to: ${AppConstants.wsStatusTopic}');
    _stompClient!.subscribe(
      destination: AppConstants.wsStatusTopic,
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            print('🟢 Status update received: $data');
            final userStatus = UserStatus.fromJson(data);
            _statusController.add(userStatus);
          } catch (e) {
            print('❌ Error parsing status update: $e');
          }
        }
      },
    );

    // Send add user message
    if (_currentUserId != null && _currentUsername != null) {
      print('👋 Sending addUser for: $_currentUserId');
      sendAddUser(_currentUserId!, _currentUsername!);
    }
  }

  void _onDisconnect(StompFrame frame) {
    print('WebSocket disconnected');
    _connectionController.add(false);
  }

  void sendMessage({
    required String content,
    required String recipientId,
    String? recipientName,
    String? chatId,
  }) {
    if (_stompClient?.connected != true) {
      print('❌ WebSocket not connected');
      return;
    }

    // Backend expects: chatId, content, recipientId
    final messagePayload = {
      'chatId': chatId ?? generateChatId(_currentUserId!, recipientId),
      'content': content,
      'recipientId': recipientId,
      'senderId': _currentUserId,
    };

    print('📤 Sending message payload: $messagePayload');
    print('📍 To destination: ${AppConstants.wsSendMessage}');

    _stompClient!.send(
      destination: AppConstants.wsSendMessage,
      body: jsonEncode(messagePayload),
    );

    print('✅ Message sent successfully');
  }

  String generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    final combined = '${ids[0]}_${ids[1]}';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16);
  }

  void sendTypingIndicator(String recipientId, String? recipientName) {
    if (_stompClient?.connected != true) return;

    // Backend expects simple Map<String, String>, not ChatMessage
    final typingPayload = {
      'recipientId': recipientId,
    };

    _stompClient!.send(
      destination: AppConstants.wsTyping,
      body: jsonEncode(typingPayload),
    );
  }

  void sendAddUser(String userId, String username) {
    if (_stompClient?.connected != true) return;

    // Backend expects simple Map<String, String>, not ChatMessage
    final userPayload = {
      'userId': userId,
      'username': username,
    };

    _stompClient!.send(
      destination: AppConstants.wsAddUser,
      body: jsonEncode(userPayload),
    );
  }

  void markMessageAsRead(String messageId, String senderId) {
    if (_stompClient?.connected != true) return;

    _stompClient!.send(
      destination: AppConstants.wsMarkRead,
      body: jsonEncode({
        'messageId': messageId,
        'senderId': senderId,
      }),
    );
  }

  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _statusController.close();
    _connectionController.close();
  }
}
