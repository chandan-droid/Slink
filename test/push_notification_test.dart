import 'package:flutter_test/flutter_test.dart';
import 'package:slink_app/core/config/app_config.dart';
import 'package:slink_app/core/notifications/push_notification_service.dart';
import 'package:slink_app/features/notification/data/models/device_dto.dart';
import 'package:slink_app/features/notification/data/models/notification_dto.dart';
import 'package:slink_app/features/notification/domain/entities/app_notification.dart';

void main() {
  group('Push Notifications - Device & Notification DTO Tests', () {
    test('DeviceRegistrationRequest serializes to backend expected JSON', () {
      const req = DeviceRegistrationRequest(
        deviceToken: 'fcm-token-1234567890',
        platform: 'ANDROID',
      );

      final json = req.toJson();
      expect(json['deviceToken'], equals('fcm-token-1234567890'));
      expect(json['platform'], equals('ANDROID'));
    });

    test('DeviceResponseDto parses backend response correctly', () {
      final json = {
        'id': 'device-uuid-1',
        'userId': 'user-uuid-1',
        'deviceToken': 'fcm-token-1234567890',
        'platform': 'ANDROID',
        'createdAt': '2026-10-30T10:00:00.000Z',
        'lastActiveAt': '2026-10-30T11:00:00.000Z',
      };

      final dto = DeviceResponseDto.fromJson(json);
      expect(dto.id, equals('device-uuid-1'));
      expect(dto.userId, equals('user-uuid-1'));
      expect(dto.deviceToken, equals('fcm-token-1234567890'));
      expect(dto.platform, equals('ANDROID'));
      expect(dto.createdAt, isNotNull);
    });

    test('NotificationDto parses title, body, and referenceId', () {
      final json = {
        'id': 'notif-1',
        'type': 'NEW_MESSAGE',
        'title': 'New message from alice',
        'body': 'Hey, how are you?',
        'referenceId': 'msg-123',
        'isRead': false,
        'createdAt': '2026-10-30T10:05:00.000Z',
      };

      final dto = NotificationDto.fromJson(json);
      expect(dto.id, equals('notif-1'));
      expect(dto.type, equals(NotificationType.newMessage));
      expect(dto.title, equals('New message from alice'));
      expect(dto.body, equals('Hey, how are you?'));
      expect(dto.referenceId, equals('msg-123'));
      expect(dto.isRead, isFalse);

      final entity = AppNotification.fromDto(dto);
      expect(entity.title, equals('New message from alice'));
      expect(entity.body, equals('Hey, how are you?'));
    });

    test('PushNotificationService configuration constants match server', () {
      expect(PushNotificationService.channelId, equals('slink_messages'));
      expect(PushNotificationService.channelName, equals('Messages'));
      expect(AppConfig.devicesEndpoint, equals('/api/users/devices'));
    });
  });
}

