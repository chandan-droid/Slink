import '../../../../core/utils/date_utils.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

class MessageDto {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderUsername;
  final String? recipientId;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;

  const MessageDto({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderUsername,
    this.recipientId,
    required this.content,
    this.status = MessageStatus.sent,
    required this.createdAt,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) => MessageDto(
        id: json['id']?.toString() ?? '',
        chatId: json['chatId']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        senderUsername: json['senderUsername']?.toString(),
        recipientId: json['recipientId']?.toString(),
        content: json['content']?.toString() ?? '',
        status: _parseStatus(json['status']?.toString()),
        createdAt: SlinkDateUtils.parseDate(
            json['sentAt']?.toString() ??
                json['createdAt']?.toString() ??
                json['timestamp']?.toString()),
      );

  factory MessageDto.fromDb(Map<String, dynamic> row) => MessageDto(
        id: row['id'] as String,
        chatId: row['chatId'] as String,
        senderId: row['senderId'] as String,
        recipientId: row['recipientId'] as String?,
        content: row['content'] as String,
        status: _parseStatus(row['status'] as String?),
        createdAt: SlinkDateUtils.parseDate(row['createdAt'] as String?),
      );

  Map<String, dynamic> toDbRow() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'recipientId': recipientId,
        'content': content,
        'status': status.name.toUpperCase(),
        'createdAt': createdAt.toIso8601String(),
      };

  static MessageStatus _parseStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'DELIVERED':
        return MessageStatus.delivered;
      case 'READ':
        return MessageStatus.read;
      case 'FAILED':
        return MessageStatus.failed;
      case 'SENDING':
        return MessageStatus.sending;
      default:
        return MessageStatus.sent;
    }
  }

  MessageDto copyWith({MessageStatus? status}) => MessageDto(
        id: id,
        chatId: chatId,
        senderId: senderId,
        senderUsername: senderUsername,
        recipientId: recipientId,
        content: content,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) => other is MessageDto && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
