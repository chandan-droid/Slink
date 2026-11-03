import '../../data/models/message_dto.dart';

export '../../data/models/message_dto.dart' show MessageStatus;

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderUsername;
  final String? recipientId;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderUsername,
    this.recipientId,
    required this.content,
    this.status = MessageStatus.sent,
    required this.createdAt,
  });

  factory Message.fromDto(MessageDto dto) => Message(
        id: dto.id,
        chatId: dto.chatId,
        senderId: dto.senderId,
        senderUsername: dto.senderUsername,
        recipientId: dto.recipientId,
        content: dto.content,
        status: dto.status,
        createdAt: dto.createdAt,
      );

  MessageDto toDto() => MessageDto(
        id: id,
        chatId: chatId,
        senderId: senderId,
        senderUsername: senderUsername,
        recipientId: recipientId,
        content: content,
        status: status,
        createdAt: createdAt,
      );

  Message copyWith({MessageStatus? status}) => Message(
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
  bool operator ==(Object other) => other is Message && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
