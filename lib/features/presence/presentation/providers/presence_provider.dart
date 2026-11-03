import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/websocket/stomp_service.dart';
import '../../../contacts/domain/entities/platform_user.dart';
import '../../data/models/presence_dto.dart';

/// Maintains a live map of userId → OnlineStatus fed by STOMP /topic/user.status
class PresenceNotifier extends StateNotifier<Map<String, OnlineStatus>> {
  final SlinkStompService _stomp;
  StreamSubscription? _sub;

  PresenceNotifier(this._stomp) : super({}) {
    _sub = _stomp.statusStream.listen(_onStatus);
  }

  void _onStatus(Map<String, dynamic> data) {
    final dto = PresenceDto.fromJson(data);
    if (dto.userId.isEmpty) return;
    final status = _parse(dto.status);
    state = {...state, dto.userId: status};
  }

  static OnlineStatus _parse(String s) {
    switch (s.toUpperCase()) {
      case 'ONLINE':
        return OnlineStatus.online;
      case 'AWAY':
        return OnlineStatus.away;
      default:
        return OnlineStatus.offline;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final presenceProvider =
    StateNotifierProvider<PresenceNotifier, Map<String, OnlineStatus>>((ref) {
  return PresenceNotifier(ref.read(stompServiceProvider));
});

/// Convenience alias
final presenceMapProvider = presenceProvider;

