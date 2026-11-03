import '../../data/models/notification_dto.dart';
export '../../data/models/notification_dto.dart' show NotificationType;

class AppNotification {
  final String id;
  final NotificationType type;
  final String? title;
  final String? body;
  final String? referenceId;
  final String? payload;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.referenceId,
    this.payload,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromDto(NotificationDto dto) => AppNotification(
        id: dto.id,
        type: dto.type,
        title: dto.title,
        body: dto.body,
        referenceId: dto.referenceId,
        payload: dto.payload ?? dto.body,
        isRead: dto.isRead,
        createdAt: dto.createdAt,
      );

  AppNotification copyWith({
    bool? isRead,
    String? title,
    String? body,
    String? referenceId,
    String? payload,
  }) =>
      AppNotification(
        id: id,
        type: type,
        title: title ?? this.title,
        body: body ?? this.body,
        referenceId: referenceId ?? this.referenceId,
        payload: payload ?? this.payload,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
