import '../entities/message.dart';

abstract class MessageRepository {
  Future<List<Message>> getHistory(String chatId);
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    required String recipientId,
    required String senderId,
  });
  Future<void> saveLocal(Message message);
  Future<void> markRead({
    required String messageId,
    required String chatId,
    required String originalSenderId,
  });
}
