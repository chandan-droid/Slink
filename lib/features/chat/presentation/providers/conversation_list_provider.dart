import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/websocket/stomp_service.dart';
import '../../domain/entities/conversation.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../community/data/repositories/community_repository_impl.dart';

class ConversationListNotifier extends StateNotifier<List<Conversation>> {
  final LocalDb _db;
  final Ref _ref;
  StreamSubscription? _msgSub;

  ConversationListNotifier(this._db, this._ref) : super([]) {
    _load();
    _msgSub = _ref.read(stompServiceProvider).messageStream.listen(_onMessage);
  }

  Future<void> _load() async {
    final rows = await _db.getConversations();
    if (!mounted) return;
    state = rows
        .map((r) => Conversation(
              chatId: r['chatId'] as String,
              participantId: r['participantId'] as String,
              participantName: r['participantName'] as String,
              lastMessage: r['lastMessage'] as String?,
              lastMessageTime: r['lastMessageTime'] != null
                  ? SlinkDateUtils.parseDate(r['lastMessageTime'] as String)
                  : null,
              unreadCount: (r['unreadCount'] as int?) ?? 0,
              isGroup: (r['isGroup'] as int?) ?? 0,
              communityId: r['communityId'] as String?,
              communityName: r['communityName'] as String?,
              groupTitle: r['groupTitle'] as String?,
            ))
        .toList();
  }

  void _onMessage(Map<String, dynamic> data) {
    final chatId = data['chatId']?.toString() ?? '';
    final content = data['content']?.toString() ?? '';
    final senderId = data['senderId']?.toString() ?? '';
    if (chatId.isEmpty) return;

    final now = DateTime.now();
    final idx = state.indexWhere((c) => c.chatId == chatId);

    if (idx >= 0) {
      final updated = state[idx].copyWith(
        lastMessage: content,
        lastMessageTime: now,
        unreadCount: state[idx].unreadCount + 1,
      );
      final list = [...state];
      list[idx] = updated;
      list.sort((a, b) => (b.lastMessageTime ?? DateTime(0))
          .compareTo(a.lastMessageTime ?? DateTime(0)));
      state = list;

      _db.upsertConversation({
        'chatId': chatId,
        'participantId': updated.participantId,
        'participantName': updated.participantName,
        'lastMessage': content,
        'lastMessageTime': now.toIso8601String(),
        'unreadCount': updated.unreadCount,
        'isGroup': updated.isGroup,
        'communityId': updated.communityId,
        'communityName': updated.communityName,
        'groupTitle': updated.groupTitle,
      });
    } else {
      _fetchAndAddConversation(chatId, senderId, content, now);
    }
  }

  void upsertSentMessage({
    required String chatId,
    required String content,
    required String recipientId,
    required DateTime time,
  }) {
    final idx = state.indexWhere((c) => c.chatId == chatId);
    if (idx >= 0) {
      final updated = state[idx].copyWith(
        lastMessage: content,
        lastMessageTime: time,
      );
      final list = [...state];
      list[idx] = updated;
      list.sort((a, b) => (b.lastMessageTime ?? DateTime(0))
          .compareTo(a.lastMessageTime ?? DateTime(0)));
      state = list;

      _db.upsertConversation({
        'chatId': chatId,
        'participantId': updated.participantId,
        'participantName': updated.participantName,
        'lastMessage': content,
        'lastMessageTime': time.toIso8601String(),
        'unreadCount': updated.unreadCount,
        'isGroup': updated.isGroup,
        'communityId': updated.communityId,
        'communityName': updated.communityName,
        'groupTitle': updated.groupTitle,
      });
    }
  }

  Future<void> _fetchAndAddConversation(
      String chatId, String senderId, String content, DateTime now) async {
    try {
      final details = await _ref.read(chatRepositoryProvider).getChatDetails(chatId);
      final typeStr = details['type']?.toString();
      final title = details['title']?.toString() ?? 'Group';
      final communityId = details['communityId']?.toString();

      int isGroup = 0;
      String participantName = title;
      String? communityName;

      if (typeStr == 'GROUP') {
        if (communityId != null && communityId.isNotEmpty) {
          isGroup = 2; // community chat
          try {
            final comm = await _ref.read(communityRepositoryProvider).getCommunityById(communityId);
            communityName = comm.name;
          } catch (_) {
            communityName = 'Community';
          }
        } else {
          isGroup = 1; // standalone group
        }
      }

      if (isGroup == 0) {
        participantName = details['title']?.toString() ?? senderId;
      }

      final convo = Conversation(
        chatId: chatId,
        participantId: isGroup > 0 ? '' : senderId,
        participantName: participantName,
        lastMessage: content,
        lastMessageTime: now,
        unreadCount: 1,
        isGroup: isGroup,
        communityId: communityId,
        communityName: communityName,
        groupTitle: isGroup > 0 ? title : null,
      );

      if (!mounted) return;
      state = [convo, ...state]
        ..sort((a, b) => (b.lastMessageTime ?? DateTime(0))
            .compareTo(a.lastMessageTime ?? DateTime(0)));

      _db.upsertConversation({
        'chatId': chatId,
        'participantId': convo.participantId,
        'participantName': convo.participantName,
        'lastMessage': content,
        'lastMessageTime': now.toIso8601String(),
        'unreadCount': 1,
        'isGroup': isGroup,
        'communityId': communityId,
        'communityName': communityName,
        'groupTitle': convo.groupTitle,
      });
    } catch (_) {
      if (!mounted) return;
      final convo = Conversation(
        chatId: chatId,
        participantId: senderId,
        participantName: senderId,
        lastMessage: content,
        lastMessageTime: now,
        unreadCount: 1,
      );
      state = [convo, ...state];
      _db.upsertConversation({
        'chatId': chatId,
        'participantId': senderId,
        'participantName': senderId,
        'lastMessage': content,
        'lastMessageTime': now.toIso8601String(),
        'unreadCount': 1,
      });
    }
  }

  /// Called when the user taps a contact and opens a chat for the first time.
  void upsertFromOpen(
    String chatId,
    String participantId,
    String participantName, {
    int isGroup = 0,
    String? communityId,
    String? communityName,
    String? groupTitle,
  }) {
    if (state.any((c) => c.chatId == chatId)) return;
    final now = DateTime.now();
    state = [
      Conversation(
        chatId: chatId,
        participantId: participantId,
        participantName: participantName,
        lastMessageTime: now,
        isGroup: isGroup,
        communityId: communityId,
        communityName: communityName,
        groupTitle: groupTitle,
      ),
      ...state,
    ];
    _db.upsertConversation({
      'chatId': chatId,
      'participantId': participantId,
      'participantName': participantName,
      'lastMessage': null,
      'lastMessageTime': now.toIso8601String(),
      'unreadCount': 0,
      'isGroup': isGroup,
      'communityId': communityId,
      'communityName': communityName,
      'groupTitle': groupTitle,
    });
  }

  void clearUnread(String chatId) {
    final idx = state.indexWhere((c) => c.chatId == chatId);
    if (idx < 0) return;
    final list = [...state];
    final convo = state[idx].copyWith(unreadCount: 0);
    list[idx] = convo;
    state = list;

    _db.upsertConversation({
      'chatId': chatId,
      'participantId': convo.participantId,
      'participantName': convo.participantName,
      'lastMessage': convo.lastMessage,
      'lastMessageTime': convo.lastMessageTime?.toIso8601String(),
      'unreadCount': 0,
      'isGroup': convo.isGroup,
      'communityId': convo.communityId,
      'communityName': convo.communityName,
      'groupTitle': convo.groupTitle,
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }
}

final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, List<Conversation>>((ref) {
  return ConversationListNotifier(LocalDb(), ref);
});
