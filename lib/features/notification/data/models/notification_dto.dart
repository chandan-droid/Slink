import '../../../../core/utils/date_utils.dart';

enum NotificationType { newMessage, readReceipt, userStatusChange, system }

class NotificationDto {
  final String id;
  final NotificationType type;
  final String? title;
  final String? body;
  final String? referenceId;
  final String? payload;
  final bool isRead;
  final DateTime createdAt;

  const NotificationDto({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.referenceId,
    this.payload,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      NotificationDto(
        id: json['id']?.toString() ?? '',
        type: _parseType(json['type']?.toString()),
        title: json['title']?.toString(),
        body: json['body']?.toString(),
        referenceId: json['referenceId']?.toString(),
        payload: json['payload']?.toString() ?? json['body']?.toString(),
        isRead: json['isRead'] == true,
        createdAt: SlinkDateUtils.parseDate(json['createdAt']?.toString()),
      );

  static NotificationType _parseType(String? s) {
    switch (s?.toUpperCase()) {
      case 'NEW_MESSAGE':
        return NotificationType.newMessage;
      case 'READ_RECEIPT':
        return NotificationType.readReceipt;
      case 'USER_STATUS_CHANGE':
        return NotificationType.userStatusChange;
      default:
        return NotificationType.system;
    }
  }
}
