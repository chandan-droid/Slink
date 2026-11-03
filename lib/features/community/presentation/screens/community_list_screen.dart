import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_strings.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/community.dart';
import '../providers/community_list_provider.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final commAsync = ref.watch(communityListProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          AppStrings.communities,
          style: AppTextStyles.h2.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: c.accent,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                tooltip: 'Create Community',
                onPressed: _showCreateCommunityDialog,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          commAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: c.accent)),
            error: (e, _) => ErrorView(
              message: NetworkException.parseError(e),
              onRetry: () => ref.invalidate(communityListProvider),
            ),
            data: (communities) {
              if (communities.isEmpty) {
                return const EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No communities yet',
                  subtitle: 'Create or join a community to start group discussions.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: communities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CommunityCard(
                  community: communities[i],
                  onTap: () => _showCommunityDetails(communities[i]),
                ),
              );
            },
          ),
          if (_isLoading) ...[
            const ModalBarrier(
              dismissible: false,
              color: Colors.black45,
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
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

  void _showCreateCommunityDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final c = AppColors.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Create Community',
            style: AppTextStyles.h2.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Community Name',
                    hintText: 'e.g. Flutter Developers',
                    prefixIcon: Icon(Icons.groups_rounded, color: c.accent),
                    fillColor: c.inputBackground,
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'What is this community about?',
                    prefixIcon: Icon(Icons.description_outlined, color: c.accent),
                    fillColor: c.inputBackground,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: c.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  Navigator.pop(dialogContext);

                  await Future.delayed(Duration.zero);
                  if (!mounted) return;

                  setState(() => _isLoading = true);

                  try {
                    await ref.read(communityRepositoryProvider).createCommunity(
                      name: name,
                      description: desc.isNotEmpty ? desc : null,
                    );
                    ref.invalidate(communityListProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Community created successfully!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(NetworkException.parseError(e)),
                          backgroundColor: c.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showCommunityDetails(Community community) {
    final c = AppColors.of(context);
    final currentUserId = ref.read(currentUserIdProvider);
    final isOwner = community.ownerId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (dialogContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        AvatarWidget(name: community.name, radius: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.name,
                                style: AppTextStyles.h2.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.people_outline, color: c.textMuted, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${community.memberCount} members',
                                    style: AppTextStyles.bodySmall.copyWith(color: c.textMuted),
                                  ),
                                  if (isOwner) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: c.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Owner',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: c.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (community.description != null && community.description!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          community.description!,
                          style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Channels',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isOwner)
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Room'),
                            style: TextButton.styleFrom(foregroundColor: c.accent),
                            onPressed: () async {
                              final navigator = Navigator.of(bottomSheetContext);
                              final title = await _showCreateCommunityChatRoomDialog(dialogContext);
                              if (title != null && title.trim().isNotEmpty) {
                                navigator.pop();
                                await Future.delayed(Duration.zero);
                                if (mounted) {
                                  setState(() => _isLoading = true);
                                  try {
                                    final newChat = await ref
                                        .read(communityRepositoryProvider)
                                        .createCommunityChat(
                                          communityId: community.id,
                                          title: title.trim(),
                                        );
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                      final chatId = newChat['id']?.toString() ?? '';
                                      if (chatId.isNotEmpty) {
                                        context.push(Routes.chatPath(chatId), extra: {
                                          'recipientId': '',
                                          'recipientName': community.name,
                                          'recipientStatus': 'ONLINE',
                                          'isGroup': 2,
                                          'communityId': community.id,
                                          'communityName': community.name,
                                          'groupTitle': title.trim(),
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
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
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: ref.read(communityRepositoryProvider).getCommunityChats(community.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: c.accent),
                              ),
                            );
                          }
                          final chats = snapshot.data ?? [];
                          if (chats.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No extra channels yet. Click Enter General Chat below.',
                                  style: TextStyle(color: c.textMuted, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: chats.length,
                            itemBuilder: (context, idx) {
                              final chat = chats[idx];
                              final title = chat['title']?.toString() ?? 'Room';
                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                leading: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: c.accent.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.tag_rounded, color: c.accent, size: 16),
                                ),
                                title: Text(
                                  title,
                                  style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios_rounded, color: c.textMuted, size: 12),
                                onTap: () {
                                  Navigator.pop(bottomSheetContext);
                                  _enterChat(community, title: title);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                      label: const Text('Enter General Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.of(bottomSheetContext).pop();
                        await Future.delayed(Duration.zero);
                        if (mounted) {
                          _enterChat(community, title: 'General');
                        }
                      },
                    ),
                    if (!isOwner) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                        label: const Text('Leave Community'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.error,
                          side: BorderSide(color: c.error.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(bottomSheetContext).pop();
                          await Future.delayed(Duration.zero);
                          if (mounted) {
                            _leaveCommunity(community);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showCreateCommunityChatRoomDialog(BuildContext context) {
    final controller = TextEditingController();
    final c = AppColors.of(context);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'New Channel',
            style: AppTextStyles.h3.copyWith(color: c.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              labelText: 'Channel Title',
              hintText: 'e.g. general, announcements',
              prefixIcon: Icon(Icons.tag_rounded, color: c.accent),
              fillColor: c.inputBackground,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: c.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _enterChat(Community community, {String title = 'General'}) async {
    try {
      setState(() => _isLoading = true);

      final chatId = await ref.read(communityRepositoryProvider).startCommunityChat(
            communityId: community.id,
            title: title,
          );

      if (mounted) {
        context.push(Routes.chatPath(chatId), extra: {
          'recipientId': '',
          'recipientName': community.name,
          'recipientStatus': 'ONLINE',
          'isGroup': 2,
          'communityId': community.id,
          'communityName': community.name,
          'groupTitle': title,
        });
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('User is not a member of this community')) {
        if (mounted) {
          _showJoinPrompt(community);
        }
      } else {
        if (mounted) {
          final c = AppColors.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(NetworkException.parseError(e)),
              backgroundColor: c.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJoinPrompt(Community community) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Join Community?',
            style: AppTextStyles.h2.copyWith(color: c.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You are not a member of "${community.name}" yet. Would you like to join this community to start chatting?',
            style: TextStyle(color: c.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: c.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Future.delayed(Duration.zero);
                if (mounted) {
                  _joinAndEnterChat(community);
                }
              },
              child: const Text('Join Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinAndEnterChat(Community community, {String title = 'General'}) async {
    final c = AppColors.of(context);
    try {
      setState(() => _isLoading = true);
      await ref.read(communityRepositoryProvider).joinCommunity(community.id);
      ref.invalidate(communityListProvider);

      final chatId = await ref.read(communityRepositoryProvider).startCommunityChat(
            communityId: community.id,
            title: title,
          );

      if (mounted) {
        context.push(Routes.chatPath(chatId), extra: {
          'recipientId': '',
          'recipientName': community.name,
          'recipientStatus': 'ONLINE',
          'isGroup': 2,
          'communityId': community.id,
          'communityName': community.name,
          'groupTitle': title,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkException.parseError(e)),
            backgroundColor: c.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveCommunity(Community community) async {
    final c = AppColors.of(context);
    try {
      setState(() => _isLoading = true);
      await ref.read(communityRepositoryProvider).leaveCommunity(community.id);
      ref.invalidate(communityListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left community successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkException.parseError(e)),
            backgroundColor: c.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback onTap;
  const _CommunityCard({required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : c.divider.withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AvatarWidget(name: community.name, radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: AppTextStyles.username.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        community.description != null && community.description!.isNotEmpty
                            ? community.description!
                            : 'Tap to view channels and discussions',
                        style: AppTextStyles.bodySmall.copyWith(color: c.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_rounded, color: c.accent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${community.memberCount}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: c.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, color: c.textMuted, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
