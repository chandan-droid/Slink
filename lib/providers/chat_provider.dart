import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService();

  List<UserModel> _users = [];
  List<MessageModel> _messages = [];
  Map<String, bool> _typingUsers = {};
  bool _isLoading = false;
  String? _error;
  bool _isConnected = false;
  String? _currentChatId;
  String? _currentRecipientId;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _typingTimer;

  List<UserModel> get users => _users;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;

  bool isUserTyping(String userId) => _typingUsers[userId] ?? false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  void init() {
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    // Incoming messages from WebSocket
    _messageSubscription = _webSocketService.messageStream.listen((chatMessage) async {
      if (chatMessage.content == null || chatMessage.senderId == null) return;

      print('📨 Received message: ${chatMessage.content} from ${chatMessage.senderId}');
      final message = MessageModel(
        id: chatMessage.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: chatMessage.chatId ?? _currentChatId,
        content: chatMessage.content ?? '',
        senderId: chatMessage.senderId!,
        recipientId: chatMessage.recipientId,
        createdAt: chatMessage.timestamp,
        status: MessageStatus.delivered,
      );

      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
      }

      // ✅ Mark as read immediately if this chat is open and user is the recipient
      if (message.recipientId == _currentRecipientId) {
        await markMessageAsRead(message.id, message.senderId!);
      }
    });


    // Typing indicators
    _typingSubscription = _webSocketService.typingStream.listen((typingData) {
      if (typingData.senderId != null) {
        print('⌨️ User ${typingData.senderId} is typing');
        _typingUsers[typingData.senderId!] = true;
        notifyListeners();

        Future.delayed(const Duration(seconds: 3), () {
          _typingUsers[typingData.senderId!] = false;
          notifyListeners();
        });
      }
    });

    // User status updates
    _statusSubscription = _webSocketService.statusStream.listen((userStatus) {
      final index = _users.indexWhere((u) => u.id == userStatus.userId);
      if (index != -1) {
        OnlineStatus status;
        switch (userStatus.status) {
          case Status.online:
            status = OnlineStatus.online;
            break;
          case Status.away:
            status = OnlineStatus.away;
            break;
          case Status.offline:
            status = OnlineStatus.offline;
            break;
        }
        _users[index] = _users[index].copyWith(onlineStatus: status);
        notifyListeners();
      }
    });

    // Connection status
    _connectionSubscription = _webSocketService.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------------------
  // Data Fetch
  // ---------------------------------------------------------------------------
  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _apiService.getUsers();

    if (response.isSuccess && response.data != null) {
      _users = response.data!;
    } else {
      _error = response.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchChatHistory(String chatId) async {
    _isLoading = true;
    _error = null;
    _currentChatId = chatId;
    notifyListeners();

    final response = await _apiService.getChatHistory(chatId);

    if (response.isSuccess && response.data != null) {
      _messages = response.data!;
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      _error = response.error;
      _messages = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCurrentChat(String chatId, String recipientId) {
    _currentChatId = chatId;
    _currentRecipientId = recipientId;
    _messages = [];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Message Send
  // ---------------------------------------------------------------------------
  Future<void> sendMessage({
    required String content,
    required String recipientId,
    required String senderId,
    String? recipientName,
    String? chatId,
  }) async {
    final effectiveChatId = chatId ?? _currentChatId;
    if (effectiveChatId == null) {
      print('❌ No chatId set for message');
      return;
    }

    // 1️⃣ Optimistic UI update
    final optimisticMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: effectiveChatId,
      content: content,
      senderId: senderId,
      recipientId: recipientId,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    _messages.add(optimisticMessage);
    notifyListeners();

    // 2️⃣ Send via REST (persistence)
    final response = await _apiService.sendMessage(effectiveChatId, content);

    if (response.isSuccess && response.data != null) {
      print('✅ Message saved to DB');
      _messages.removeWhere((m) => m.id == optimisticMessage.id);
      _messages.add(response.data!);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    } else {
      print('❌ REST send failed: ${response.error}');
    }

    // 3️⃣ Send via WebSocket (real-time broadcast)
    _webSocketService.sendMessage(
      chatId: effectiveChatId,
      content: content,
      recipientId: recipientId,
      recipientName: recipientName,
    );
  }

  // ---------------------------------------------------------------------------
  // Typing & Read
  // ---------------------------------------------------------------------------
  Future<void> markMessageAsRead(String messageId, String senderId) async {
    // Update local state
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: MessageStatus.read);
      notifyListeners();
    }

    // Notify backend (WebSocket + REST)
    _webSocketService.markMessageAsRead(messageId, senderId);
    await _apiService.markMessageAsRead(messageId);
  }


  void sendTypingIndicator(String recipientId, String? recipientName) {
    _webSocketService.sendTypingIndicator(recipientId, recipientName);
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------
  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}
