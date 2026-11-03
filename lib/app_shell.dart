import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/theme/app_colors.dart';
import 'core/config/theme/app_text_styles.dart';
import 'core/router/route_names.dart';
import 'features/notification/presentation/providers/notification_list_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    Routes.home,
    Routes.communityList,
    Routes.contacts,
    Routes.notifications,
  ];

  static int _indexForLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final unread = ref.watch(unreadCountProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(
            top: BorderSide(
              color: c.divider.withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
        ),
        child: NavigationBar(
          elevation: 0,
          backgroundColor: c.surface,
          indicatorColor: c.accent.withValues(alpha: 0.16),
          selectedIndex: currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          onDestinationSelected: (i) => context.go(_tabs[i]),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 22),
              selectedIcon: Icon(Icons.chat_bubble_rounded, size: 22),
              label: 'Chats',
            ),
            const NavigationDestination(
              icon: Icon(Icons.groups_outlined, size: 24),
              selectedIcon: Icon(Icons.groups_rounded, size: 24),
              label: 'Communities',
            ),
            const NavigationDestination(
              icon: Icon(Icons.contacts_outlined, size: 22),
              selectedIcon: Icon(Icons.contacts_rounded, size: 22),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                backgroundColor: c.error,
                label: Text(
                  '$unread',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 24),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                backgroundColor: c.error,
                label: Text(
                  '$unread',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                child: const Icon(Icons.notifications_rounded, size: 24),
              ),
              label: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }
}
