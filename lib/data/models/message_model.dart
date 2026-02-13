enum MessageStatus { sent, delivered, read }

class MessageModel {
  final String id;
  final String? chatId;
  final String content;
  final String senderId;
  final String? recipientId;
  final DateTime createdAt;
  final MessageStatus status;

  MessageModel({
    required this.id,
    this.chatId,
    required this.content,
    required this.senderId,
    this.recipientId,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chatId'],
      content: json['content'] ?? '',
      senderId: json['senderId'] ?? '',
      recipientId: json['recipientId'],
      createdAt: _parseDateTime(json['createdAt'] ?? json['timestamp']),
      status: _parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'content': content,
      'senderId': senderId,
      'recipientId': recipientId,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name.toUpperCase(),
    };
  }

  static DateTime _parseDateTime(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      // Try parsing as ISO-8601 first (from Message entity)
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      // Then try parsing as "yyyy-MM-dd HH:mm:ss" format (from MessageDTO)
      if (dateStr.contains(' ')) {
        final parts = dateStr.split(' ');
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        return DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          int.parse(timeParts[2]),
        );
      }
      return DateTime.parse(dateStr);
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
      return DateTime.now();
    }
  }

  static MessageStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'DELIVERED':
        return MessageStatus.delivered;
      case 'READ':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? content,
    String? senderId,
    String? recipientId,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  bool get isFromMe => false; // Will be set in context

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isRead => status == MessageStatus.read;

}
