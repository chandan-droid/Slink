import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/websocket/stomp_service.dart';
import '../../data/models/notification_dto.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationListNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repo;
  StreamSubscription? _sub;

  NotificationListNotifier(this._repo, SlinkStompService stomp)
      : super(const AsyncValue.loading()) {
    _load();
    _sub = stomp.notificationStream.listen(_onPush);
  }

  Future<void> _load() async {
    try {
      final list = await _repo.getNotifications();
      if (mounted) state = AsyncValue.data(list);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _onPush(Map<String, dynamic> data) {
    final notif = AppNotification.fromDto(
        NotificationDto.fromJson(data));
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([notif, ...current]);
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.map((n) => n.copyWith(isRead: true)).toList());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final notificationListProvider = StateNotifierProvider<NotificationListNotifier,
    AsyncValue<List<AppNotification>>>((ref) {
  return NotificationListNotifier(
    ref.read(notificationRepositoryProvider),
    ref.read(stompServiceProvider),
  );
});

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationListProvider).valueOrNull ?? [];
  return notifs.where((n) => !n.isRead).length;
});

