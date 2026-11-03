import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/message/presentation/screens/chat_screen.dart';
import '../../features/community/presentation/screens/community_list_screen.dart';
import '../../features/notification/presentation/screens/notifications_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../app_shell.dart';
import '../storage/secure_storage.dart';
import '../utils/logger.dart';
import 'route_names.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Observer that prints navigation changes.
class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppLogger.info(
      'Navigation: didPush route = ${route.settings.name ?? route.runtimeType}\n'
      '   previous = ${previousRoute?.settings.name ?? previousRoute?.runtimeType}',
      tag: 'Router',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppLogger.info(
      'Navigation: didPop route = ${route.settings.name ?? route.runtimeType}\n'
      '   current = ${previousRoute?.settings.name ?? previousRoute?.runtimeType}',
      tag: 'Router',
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  ref.read(authProvider);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    observers: [AppNavigationObserver()],
    redirect: (context, state) async {
      final loggedIn = await SecureStorage().isLoggedIn();
      final loc = state.matchedLocation;
      AppLogger.info('Routing: location = $loc, loggedIn = $loggedIn', tag: 'Router');

      // Handle root/splash path
      if (loc == Routes.splash) {
        final dest = loggedIn ? Routes.home : Routes.login;
        AppLogger.info('Routing: splash -> redirecting to $dest', tag: 'Router');
        return dest;
      }

      final onAuth = loc == Routes.login || loc == Routes.register;
      if (!loggedIn && !onAuth) {
        AppLogger.info('Routing: access denied to secure path $loc -> login', tag: 'Router');
        return Routes.login;
      }
      if (loggedIn && onAuth) {
        AppLogger.info('Routing: authenticated user on auth screen -> home', tag: 'Router');
        return Routes.home;
      }
      return null;
    },

    routes: [
      // ── Splash Route ─────────────────────────────────────────────────────
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),

      // ── Auth routes ──────────────────────────────────────────────────────
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),

      // ── Search Route (above shell) ───────────────────────────────────────
      GoRoute(
        path: Routes.search,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SearchScreen(),
      ),

      // ── Shell with bottom nav ────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, __) => const ConversationsScreen(),
          ),
          GoRoute(
            path: Routes.communityList,
            builder: (_, __) => const CommunityListScreen(),
          ),
          GoRoute(
            path: Routes.contacts,
            builder: (_, __) => const ContactsScreen(),
          ),
          GoRoute(
            path: Routes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),

      // ── Chat — full screen above shell ───────────────────────────────────
      GoRoute(
        path: Routes.chat,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChatScreen(
            chatId: chatId,
            recipientId: extra['recipientId'] as String? ?? '',
            recipientName: extra['recipientName'] as String? ?? 'Chat',
            recipientStatus: extra['recipientStatus'] as String? ?? 'OFFLINE',
            isGroup: extra['isGroup'] as int? ?? 0,
            communityId: extra['communityId'] as String?,
            communityName: extra['communityName'] as String?,
            groupTitle: extra['groupTitle'] as String?,
          );
        },
      ),
    ],
  );
});
