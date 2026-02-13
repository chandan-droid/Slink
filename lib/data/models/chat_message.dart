enum MessageType {
  chat,
  join,
  leave,
  typing,
}

class ChatMessage {
  final String? id;
  final String? chatId;
  final String? senderId;
  final String? senderName;
  final String? senderUsername;
  final String? recipientId;
  final String? recipientName;
  final String? content;
  final String? status;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    this.id,
    this.chatId,
    this.senderId,
    this.senderName,
    this.senderUsername,
    this.recipientId,
    this.recipientName,
    this.content,
    this.status,
    DateTime? timestamp,
    this.type = MessageType.chat,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle both ChatMessage format and MessageDTO format from backend
    DateTime parseTimestamp() {
      if (json['timestamp'] != null) {
        try {
          return DateTime.parse(json['timestamp']);
        } catch (e) {
          print('Error parsing timestamp: $e');
        }
      }
      if (json['createdAt'] != null) {
        try {
          // Backend sends format: "yyyy-MM-dd HH:mm:ss"
          final dateStr = json['createdAt'] as String;
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
          print('Error parsing createdAt: $e');
        }
      }
      return DateTime.now();
    }

    return ChatMessage(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderUsername: json['senderUsername'],
      recipientId: json['recipientId'],
      recipientName: json['recipientName'],
      content: json['content'],
      status: json['status'],
      timestamp: parseTimestamp(),
      type: _parseMessageType(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderUsername': senderUsername,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'content': content,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name.toUpperCase(),
    };
  }

  static MessageType _parseMessageType(String? type) {
    switch (type?.toUpperCase()) {
      case 'CHAT':
        return MessageType.chat;
      case 'JOIN':
        return MessageType.join;
      case 'LEAVE':
        return MessageType.leave;
      case 'TYPING':
        return MessageType.typing;
      default:
        return MessageType.chat;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderUsername,
    String? recipientId,
    String? recipientName,
    String? content,
    String? status,
    DateTime? timestamp,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderUsername: senderUsername ?? this.senderUsername,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      content: content ?? this.content,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }
}
