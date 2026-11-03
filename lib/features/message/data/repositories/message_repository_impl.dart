import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../local/message_local_source.dart';
import '../models/message_dto.dart';

class MessageRepositoryImpl implements MessageRepository {
  final DioClient _dio;
  final MessageLocalSource _local;

  MessageRepositoryImpl(this._dio, this._local);

  @override
  Future<List<Message>> getHistory(String chatId) async {
    // 1. Try local cache first
    final cached = await _local.getMessages(chatId);

    // 2. Fetch from server
    try {
      final res = await _dio.dio.get('${AppConfig.chatHistoryEndpoint}/$chatId');
      if (res.data is List) {
        final remote = (res.data as List)
            .map((e) => MessageDto.fromJson(e as Map<String, dynamic>))
            .toList();
        if (remote.isNotEmpty) {
          await _local.saveAll(remote);
          return remote.map(Message.fromDto).toList();
        }
      }
      return cached.map(Message.fromDto).toList();
    } catch (e) {
      AppLogger.warning('Failed to fetch remote message history for $chatId: $e', tag: 'Messages');
      // Fall back to cache if network fails
      return cached.map(Message.fromDto).toList();
    }
  }

  @override
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    required String recipientId,
    required String senderId,
  }) async {
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final dto = MessageDto(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );
    await _local.save(dto);
    return Message.fromDto(dto);
  }

  @override
  Future<void> saveLocal(Message message) async {
    await _local.save(message.toDto());
  }

  @override
  Future<void> markRead({
    required String messageId,
    required String chatId,
    required String originalSenderId,
  }) async {
    try {
      await _dio.dio.post(
        '${AppConfig.markReadEndpoint}/$messageId',
        queryParameters: {
          'chatId': chatId,
          'originalSenderId': originalSenderId,
        },
      );
    } catch (e) {
      AppLogger.warning('REST markRead failed for message $messageId: $e', tag: 'Messages');
    }
    await _local.updateStatus(messageId, MessageStatus.read);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────
final messageLocalSourceProvider = Provider<MessageLocalSource>((ref) {
  return MessageLocalSource(LocalDb());
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(
    ref.read(dioClientProvider),
    ref.read(messageLocalSourceProvider),
  );
});
