import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_strings.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../providers/notification_list_provider.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final notifsAsync = ref.watch(notificationListProvider);
    final hasUnread = ref.watch(unreadCountProvider) > 0;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          AppStrings.notifications,
          style: AppTextStyles.h2.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (hasUnread)
            TextButton.icon(
              icon: Icon(Icons.done_all_rounded, size: 18, color: c.accent),
              label: Text(
                'Mark read',
                style: AppTextStyles.labelMedium.copyWith(
                  color: c.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () =>
                  ref.read(notificationListProvider.notifier).markAllRead(),
            ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: c.accent)),
        error: (e, _) => ErrorView(
          message: NetworkException.parseError(e),
          onRetry: () => ref.refresh(notificationListProvider),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              subtitle: 'You are all caught up! Updates and alerts will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: c.divider.withValues(alpha: 0.6),
              indent: 64,
            ),
            itemBuilder: (_, i) => _NotificationTile(notif: notifs[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notif;
  const _NotificationTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final displayTitle = (notif.title != null && notif.title!.isNotEmpty)
        ? notif.title!
        : _title(notif.type);
    final displayBody = notif.body ?? notif.payload;
    final colorScheme = _iconColor(notif.type, c);

    return InkWell(
      onTap: () {
        if (notif.referenceId != null && notif.referenceId!.isNotEmpty) {
          context.push(Routes.chatPath(notif.referenceId!), extra: {
            'recipientId': '',
            'recipientName': displayTitle,
            'recipientStatus': 'ONLINE',
          });
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.transparent : c.accent.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(notif.type), color: colorScheme, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: c.textPrimary,
                            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        SlinkDateUtils.formatTime(notif.createdAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: c.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (displayBody != null && displayBody.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      displayBody,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: notif.isRead ? c.textMuted : c.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!notif.isRead) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _icon(NotificationType t) {
    switch (t) {
      case NotificationType.newMessage:
        return Icons.chat_bubble_rounded;
      case NotificationType.readReceipt:
        return Icons.done_all_rounded;
      case NotificationType.userStatusChange:
        return Icons.person_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(NotificationType t, AppColors c) {
    switch (t) {
      case NotificationType.newMessage:
        return c.accent;
      case NotificationType.readReceipt:
        return c.online;
      case NotificationType.userStatusChange:
        return const Color(0xFF3B82F6);
      default:
        return c.accent;
    }
  }

  String _title(NotificationType t) {
    switch (t) {
      case NotificationType.newMessage:
        return 'New message';
      case NotificationType.readReceipt:
        return 'Message read';
      case NotificationType.userStatusChange:
        return 'Status changed';
      default:
        return 'Notification';
    }
  }
}
