import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_dto.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final DioClient _dio;
  NotificationRepositoryImpl(this._dio);

  @override
  Future<List<AppNotification>> getNotifications() async {
    final res = await _dio.dio.get(AppConfig.notificationsEndpoint);
    return (res.data as List)
        .map((e) => AppNotification.fromDto(
            NotificationDto.fromJson(e as Map<String, dynamic>)))
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final res = await _dio.dio.get(AppConfig.notificationsCountEndpoint);
    return (res.data as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markAllRead() =>
      _dio.dio.post(AppConfig.notificationsMarkAllRead);
}

// ─── Provider ────────────────────────────────────────────────────────────────
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.read(dioClientProvider));
});

