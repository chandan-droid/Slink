import '../../../../core/storage/local_db.dart';
import '../models/message_dto.dart';

/// SQLite-backed local message cache.
class MessageLocalSource {
  final LocalDb _db;

  MessageLocalSource(this._db);

  Future<List<MessageDto>> getMessages(String chatId) async {
    final rows = await _db.getMessages(chatId);
    return rows.map(MessageDto.fromDb).toList();
  }

  Future<void> save(MessageDto msg) => _db.insertMessage(msg.toDbRow());

  Future<void> saveAll(List<MessageDto> messages) async {
    for (final m in messages) {
      await _db.insertMessage(m.toDbRow());
    }
  }

  Future<void> updateStatus(String messageId, MessageStatus status) =>
      _db.updateMessageStatus(messageId, status.name.toUpperCase());

  Future<void> delete(String messageId) => _db.deleteMessage(messageId);
}

