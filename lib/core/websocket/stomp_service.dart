import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

/// Wraps stomp_dart_client — single connection for the entire app session.
class SlinkStompService {
  StompClient? _client;
  String? _userId;

  // Stream controllers
  final _messageCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _receiptCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _notifCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _statusCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _connCtrl = StreamController<bool>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get messageStream => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingCtrl.stream;
  Stream<Map<String, dynamic>> get receiptStream => _receiptCtrl.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notifCtrl.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusCtrl.stream;
  Stream<bool> get connectionStream => _connCtrl.stream;

  bool get isConnected => _client?.connected ?? false;
  String? get currentConnectedUserId => _userId;

  // ─── Connect ────────────────────────────────────────────────────
  void connect({
    required String token,
    required String userId,
    required String username,
  }) {
    if (isConnected && _userId == userId) {
      AppLogger.info('WebSocket is already connected for: $username ($userId)', tag: 'WebSocket');
      if (!_connCtrl.isClosed) _connCtrl.add(true);
      return;
    }

    _userId = userId;

    AppLogger.info('Initiating WebSocket connection for: $username ($userId)', tag: 'WebSocket');

    // SockJS expects HTTP/HTTPS URL for the handshake
    final normalizedUrl = AppConfig.wsUrl
        .replaceAll('wss://', 'https://')
        .replaceAll('ws://', 'http://');

    _client?.deactivate();
    _client = StompClient(
      config: StompConfig.sockJS(
        url: normalizedUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        reconnectDelay: const Duration(seconds: 4),
        onConnect: (frame) => _onConnect(frame, userId, username),
        onDisconnect: (frame) {
          AppLogger.warning('Disconnected from WebSocket', tag: 'WebSocket');
          if (!_connCtrl.isClosed) _connCtrl.add(false);
        },
        onWebSocketError: (error) {
          AppLogger.error('WebSocket connection error', tag: 'WebSocket', error: error);
          if (!_connCtrl.isClosed) _connCtrl.add(false);
        },
        onStompError: (frame) {
          AppLogger.error('Stomp error frame: ${frame.body}', tag: 'WebSocket');
          if (!_connCtrl.isClosed) _connCtrl.add(false);
        },
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame, String userId, String username) {
    AppLogger.info('Connected to WebSocket server (Command: ${frame.command})', tag: 'WebSocket');
    if (!_connCtrl.isClosed) _connCtrl.add(true);

    _subscribe(AppConfig.wsMessagesQueue, _messageCtrl);
    _subscribe(AppConfig.wsTypingQueue, _typingCtrl);
    _subscribe(AppConfig.wsReceiptsQueue, _receiptCtrl);
    _subscribe(AppConfig.wsNotificationsQueue, _notifCtrl);
    _subscribe(AppConfig.wsStatusTopic, _statusCtrl);

    // Register user as ONLINE
    sendUserStatus(userId: userId, username: username, isOnline: true);
  }

  void _subscribe(
      String destination, StreamController<Map<String, dynamic>> ctrl) {
    AppLogger.info('Subscribing to WebSocket channel: $destination', tag: 'WebSocket');
    _client?.subscribe(
      destination: destination,
      callback: (frame) {
        if (frame.body == null || frame.body!.isEmpty) return;
        AppLogger.info('Incoming WebSocket event on $destination:\n${frame.body}', tag: 'WebSocket');
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          if (!ctrl.isClosed) ctrl.add(data);
        } catch (e) {
          AppLogger.error('Failed to parse WebSocket message from $destination', tag: 'WebSocket', error: e);
        }
      },
    );
  }

  // ─── Send Actions ─────────────────────────────────────────────────
  void sendMessage({
    required String chatId,
    required String content,
    String? recipientId,
  }) {
    final payload = <String, dynamic>{
      'chatId': chatId,
      'content': content,
      if (recipientId != null && recipientId.isNotEmpty) 'recipientId': recipientId,
    };
    AppLogger.info('Dispatching message payload to ${AppConfig.wsSendMessage}:\n$payload', tag: 'WebSocket');
    _send(AppConfig.wsSendMessage, payload);
  }

  void sendTyping({required String chatId, required String recipientId}) {
    _send(AppConfig.wsTyping, {
      'chatId': chatId,
      'conversationId': chatId,
      'recipientId': recipientId,
    });
  }

  void markRead({required String messageId, required String chatId, required String senderId}) {
    _send(AppConfig.wsMarkRead, {
      'messageId': messageId,
      'chatId': chatId,
      'conversationId': chatId,
      'senderId': senderId,
    });
  }

  void sendUserStatus({
    required String userId,
    required String username,
    required bool isOnline,
  }) {
    _send(AppConfig.wsAddUser, {
      'userId': userId,
      'username': username,
      'status': isOnline ? 'ONLINE' : 'OFFLINE',
    });
  }

  void _send(String destination, Map<String, dynamic> body) {
    if (!isConnected) {
      AppLogger.warning('WebSocket not connected. Dropping send to $destination', tag: 'WebSocket');
      return;
    }
    _client?.send(
      destination: destination,
      body: jsonEncode(body),
    );
  }

  // ─── Disconnect ──────────────────────────────────────────────────
  void disconnect() {
    AppLogger.info('Disconnecting WebSocket client...', tag: 'WebSocket');
    _client?.deactivate();
    _client = null;
    _userId = null;
    if (!_connCtrl.isClosed) _connCtrl.add(false);
  }

  void dispose() {
    AppLogger.info('Disposing WebSocket streams...', tag: 'WebSocket');
    disconnect();
    _messageCtrl.close();
    _typingCtrl.close();
    _receiptCtrl.close();
    _notifCtrl.close();
    _statusCtrl.close();
    _connCtrl.close();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────
final stompServiceProvider = Provider<SlinkStompService>((ref) {
  final service = SlinkStompService();
  ref.onDispose(service.dispose);
  return service;
});

final wsConnectionProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(stompServiceProvider);
  return service.connectionStream;
});
