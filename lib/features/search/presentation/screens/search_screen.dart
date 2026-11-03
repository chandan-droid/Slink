import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/online_badge.dart';
import '../../../chat/data/repositories/chat_repository_impl.dart';
import '../../../contacts/domain/entities/platform_user.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  bool _isLoadingChat = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final resultsAsync = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: c.searchBarBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.divider.withValues(alpha: 0.3), width: 0.8),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(color: c.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search people by username…',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: c.textMuted, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: c.textMuted, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          ref.read(searchProvider.notifier).clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (q) {
                setState(() {});
                ref.read(searchProvider.notifier).search(q);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          resultsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: c.accent)),
            error: (e, _) => ErrorView(
              message: NetworkException.parseError(e),
              onRetry: () => ref.read(searchProvider.notifier).search(_ctrl.text),
            ),
            data: (users) {
              if (users.isEmpty && _ctrl.text.trim().isNotEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No users found',
                  subtitle: 'No accounts matched "${_ctrl.text.trim()}".',
                );
              }
              if (users.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'Search on Slink',
                  subtitle: 'Type a username to discover and chat with friends.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: users.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: c.divider.withValues(alpha: 0.6),
                  indent: 68,
                ),
                itemBuilder: (_, i) => _SearchUserTile(
                  user: users[i],
                  onStartChat: (user) => _startChatWithUser(user),
                ),
              );
            },
          ),
          if (_isLoadingChat) ...[
            const ModalBarrier(dismissible: false, color: Colors.black38),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CircularProgressIndicator(color: c.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startChatWithUser(PlatformUser user) async {
    setState(() => _isLoadingChat = true);
    final c = AppColors.of(context);
    try {
      final chatId = await ref.read(chatRepositoryProvider).startChat(user.id);
      if (mounted) {
        setState(() => _isLoadingChat = false);
        context.push(Routes.chatPath(chatId), extra: {
          'recipientId': user.id,
          'recipientName': user.username,
          'recipientStatus': user.onlineStatus.name.toUpperCase(),
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingChat = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkException.parseError(e)),
            backgroundColor: c.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _SearchUserTile extends StatelessWidget {
  final PlatformUser user;
  final ValueChanged<PlatformUser> onStartChat;

  const _SearchUserTile({
    required this.user,
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isOnline = user.onlineStatus == OnlineStatus.online;

    return InkWell(
      onTap: () => onStartChat(user),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                AvatarWidget(name: user.username, radius: 24),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: OnlineBadge(
                    isOnline: isOnline,
                    size: 12,
                    showBorder: true,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: AppTextStyles.username.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isOnline ? c.online : c.textMuted.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? 'Active now' : 'Offline',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isOnline ? c.online : c.textMuted,
                          fontSize: 12,
                          fontWeight: isOnline ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, color: c.accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
