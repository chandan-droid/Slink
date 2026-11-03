import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/theme/app_theme.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/utils/logger.dart';

class SlinkApp extends ConsumerStatefulWidget {
  const SlinkApp({super.key});

  @override
  ConsumerState<SlinkApp> createState() => _SlinkAppState();
}

class _SlinkAppState extends ConsumerState<SlinkApp> {
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _notifSub = PushNotificationService.instance.onNotificationClicked.listen((data) {
      AppLogger.info('Notification clicked event received: $data', tag: 'Navigation');
      final chatId = data['chatId']?.toString();
      if (chatId != null && chatId.isNotEmpty) {
        final router = ref.read(routerProvider);
        router.push(
          Routes.chatPath(chatId),
          extra: {
            'recipientId': data['senderId']?.toString() ?? '',
            'recipientName': data['senderUsername']?.toString() ?? 'Chat',
            'recipientStatus': 'ONLINE',
            'isGroup': int.tryParse(data['isGroup']?.toString() ?? '0') ?? 0,
            'groupTitle': data['groupTitle']?.toString(),
            'communityId': data['communityId']?.toString(),
            'communityName': data['communityName']?.toString(),
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Slink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
