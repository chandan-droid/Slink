import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/websocket/stomp_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/conversation_list_provider.dart';
import '../../data/models/message_dto.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../../../core/utils/logger.dart';

// ─── Per-chat message list keyed by chatId ────────────────────────────────────
class MessageListNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final String chatId;
  final MessageRepository _repo;
  final SlinkStompService _stomp;
  final String currentUserId;
  final Ref _ref;

  StreamSubscription? _msgSub;
  StreamSubscription? _receiptSub;

  MessageListNotifier({
    required this.chatId,
    required MessageRepository repo,
    required SlinkStompService stomp,
    required this.currentUserId,
    required Ref ref,
  })  : _repo = repo,
        _stomp = stomp,
        _ref = ref,
        super(const AsyncValue.loading()) {
    AppLogger.info('MessageList: Initializing MessageListNotifier for chatId = $chatId', tag: 'Messages');
    _load();
    _msgSub = stomp.messageStream.listen(_onIncoming);
    _receiptSub = stomp.receiptStream.listen(_onReceipt);
  }

  Future<void> _load() async {
    AppLogger.info('MessageList: Loading history for chatId = $chatId', tag: 'Messages');
    try {
      final msgs = await _repo.getHistory(chatId);
      AppLogger.info('MessageList: Successfully loaded ${msgs.length} messages for chatId = $chatId', tag: 'Messages');
      if (mounted) state = AsyncValue.data(msgs);
    } catch (e, st) {
      AppLogger.error('MessageList: Failed to load history for chatId = $chatId', tag: 'Messages', error: e, stackTrace: st);
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _onIncoming(Map<String, dynamic> data) {
    final incomingChatId = data['chatId']?.toString() ?? '';
    if (incomingChatId != chatId) return;

    final dto = MessageDto.fromJson(data);
    final msg = Message.fromDto(dto);
    AppLogger.info('MessageList: Incoming message in active chat: $incomingChatId (Msg ID: ${msg.id})', tag: 'Messages');
    final current = state.valueOrNull ?? [];
    if (current.any((m) => m.id == msg.id)) {
      AppLogger.debug('MessageList: Message ${msg.id} already exists in local list, skipping', tag: 'Messages');
      return;
    }

    state = AsyncValue.data([...current, msg]);
    _repo.saveLocal(msg);

    // Auto mark-read when this chat is open and we received the message
    if (msg.senderId != currentUserId && msg.senderId.isNotEmpty) {
      AppLogger.info('MessageList: Auto marking incoming message ${msg.id} as read', tag: 'Messages');
      _stomp.markRead(
        messageId: msg.id,
        chatId: chatId,
        senderId: msg.senderId,
      );
    }
  }

  void _onReceipt(Map<String, dynamic> data) {
    final messageId = data['messageId']?.toString() ?? '';
    final receiptChatId = data['chatId']?.toString() ?? '';
    if (receiptChatId.isNotEmpty && receiptChatId != chatId) return;

    AppLogger.info('MessageList: Receipt received for messageId = $messageId', tag: 'Messages');
    final current = state.valueOrNull;
    if (current == null || messageId.isEmpty) return;
    final idx = current.indexWhere((m) => m.id == messageId);
    if (idx < 0) {
      AppLogger.debug('MessageList: Message $messageId not found in local state to update status', tag: 'Messages');
      return;
    }
    final updated = [...current];
    updated[idx] = current[idx].copyWith(status: MessageStatus.read);
    state = AsyncValue.data(updated);
    _repo.saveLocal(updated[idx]);
    AppLogger.debug('MessageList: Updated message $messageId status to READ in local state', tag: 'Messages');
  }

  /// Sends a message via WebSocket and updates local SQLite and UI state immediately
  Future<void> send(String content, String recipientId) async {
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    AppLogger.info('MessageList: Initiating message send. Content length: ${content.length}. ID: $messageId', tag: 'Messages');

    final message = Message(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId,
      recipientId: recipientId,
      content: content,
      status: MessageStatus.sent,
      createdAt: now,
    );

    // Optimistically update UI
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, message]);

    // Persist to local SQLite DB
    try {
      await _repo.saveLocal(message);
    } catch (e) {
      AppLogger.warning('Failed to persist sent message locally: $e', tag: 'Messages');
    }

    // Broadcast in real-time via WebSocket
    try {
      _stomp.sendMessage(
        chatId: chatId,
        content: content,
        recipientId: recipientId,
      );
      AppLogger.info('MessageList: Message dispatched over STOMP WebSocket', tag: 'Messages');
    } catch (e, st) {
      AppLogger.error('MessageList: Failed to dispatch message over WebSocket', tag: 'Messages', error: e, stackTrace: st);
      final fresh = state.valueOrNull ?? [];
      state = AsyncValue.data(fresh
          .map((m) =>
              m.id == messageId ? m.copyWith(status: MessageStatus.failed) : m)
          .toList());
      return;
    }

    // Update conversation list item
    try {
      _ref.read(conversationListProvider.notifier).upsertSentMessage(
            chatId: chatId,
            content: content,
            recipientId: recipientId,
            time: now,
          );
    } catch (_) {}
  }

  Future<void> reload() => _load();

  @override
  void dispose() {
    AppLogger.info('MessageList: Disposing MessageListNotifier for chatId = $chatId', tag: 'Messages');
    _msgSub?.cancel();
    _receiptSub?.cancel();
    super.dispose();
  }
}

// ─── Family provider: one notifier per chatId ────────────────────────────────
final messageListProvider = StateNotifierProvider.family<MessageListNotifier,
    AsyncValue<List<Message>>, String>((ref, chatId) {
  return MessageListNotifier(
    chatId: chatId,
    repo: ref.read(messageRepositoryProvider),
    stomp: ref.read(stompServiceProvider),
    currentUserId: ref.watch(currentUserIdProvider),
    ref: ref,
  );
});
