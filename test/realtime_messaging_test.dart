import 'package:flutter_test/flutter_test.dart';
import 'package:slink_app/core/config/app_config.dart';
import 'package:slink_app/features/message/data/models/message_dto.dart';
import 'package:slink_app/features/message/domain/entities/message.dart';

void main() {
  group('Realtime Messaging - MessageDto Tests', () {
    test('Parses incoming WebSocket message from backend with sentAt', () {
      final json = {
        'id': 'msg-12345',
        'chatId': 'chat-abc',
        'senderId': 'user-1',
        'senderUsername': 'alice',
        'content': 'Hello from WebSocket!',
        'sentAt': '2026-10-30T12:00:00.000Z',
        'type': 'NEW_MESSAGE',
      };

      final dto = MessageDto.fromJson(json);

      expect(dto.id, equals('msg-12345'));
      expect(dto.chatId, equals('chat-abc'));
      expect(dto.senderId, equals('user-1'));
      expect(dto.senderUsername, equals('alice'));
      expect(dto.content, equals('Hello from WebSocket!'));
      expect(dto.status, equals(MessageStatus.sent));
      expect(dto.createdAt.year, equals(2026));
      expect(dto.createdAt.month, equals(10));
    });

    test('Parses message history date with yyyy-MM-dd HH:mm:ss format', () {
      final json = {
        'id': 'msg-999',
        'chatId': 'chat-xyz',
        'senderId': 'user-2',
        'content': 'History message',
        'status': 'READ',
        'createdAt': '2026-10-30 14:30:45',
      };

      final dto = MessageDto.fromJson(json);

      expect(dto.id, equals('msg-999'));
      expect(dto.status, equals(MessageStatus.read));
      expect(dto.createdAt.hour, equals(14));
      expect(dto.createdAt.minute, equals(30));
    });

    test('Converts Message to Dto and back correctly', () {
      final now = DateTime.now();
      final msg = Message(
        id: 'msg-test',
        chatId: 'chat-1',
        senderId: 'user-sender',
        recipientId: 'user-recip',
        content: 'Testing bidirectional conversion',
        status: MessageStatus.sent,
        createdAt: now,
      );

      final dto = msg.toDto();
      expect(dto.id, equals(msg.id));
      expect(dto.content, equals(msg.content));

      final restored = Message.fromDto(dto);
      expect(restored.id, equals(msg.id));
      expect(restored.content, equals(msg.content));
      expect(restored.status, equals(msg.status));
    });

    test('Verifies WebSocket destinations configured match backend', () {
      expect(AppConfig.wsSendMessage, equals('/app/chat.sendMessage'));
      expect(AppConfig.wsMarkRead, equals('/app/chat.markRead'));
      expect(AppConfig.wsTyping, equals('/app/chat.typing'));
      expect(AppConfig.wsAddUser, equals('/app/chat.addUser'));
      expect(AppConfig.wsMessagesQueue, equals('/user/queue/messages'));
      expect(AppConfig.wsTypingQueue, equals('/user/queue/typing'));
      expect(AppConfig.wsReceiptsQueue, equals('/user/queue/receipts'));
      expect(AppConfig.wsNotificationsQueue, equals('/user/queue/notifications'));
      expect(AppConfig.wsStatusTopic, equals('/topic/user.status'));
    });
  });
}

