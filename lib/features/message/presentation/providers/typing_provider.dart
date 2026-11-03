import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/websocket/stomp_service.dart';

/// Tracks which users are currently typing — keyed by userId.
class TypingNotifier extends StateNotifier<Map<String, bool>> {
  final SlinkStompService _stomp;
  StreamSubscription? _sub;
  final Map<String, Timer> _timers = {};

  TypingNotifier(this._stomp) : super({}) {
    _sub = _stomp.typingStream.listen(_onTyping);
  }

  void _onTyping(Map<String, dynamic> data) {
    final senderId = data['senderId']?.toString() ?? data['userId']?.toString() ?? '';
    if (senderId.isEmpty) return;

    state = {...state, senderId: true};

    _timers[senderId]?.cancel();
    _timers[senderId] = Timer(const Duration(seconds: 3), () {
      if (mounted) state = {...state, senderId: false};
    });
  }

  bool isTyping(String userId) => state[userId] ?? false;

  @override
  void dispose() {
    _sub?.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

final typingProvider =
    StateNotifierProvider<TypingNotifier, Map<String, bool>>((ref) {
  return TypingNotifier(ref.read(stompServiceProvider));
});

