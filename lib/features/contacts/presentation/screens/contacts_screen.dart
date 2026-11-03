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
import '../../../../core/widgets/online_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/repositories/chat_repository_impl.dart';
import '../../../presence/presentation/providers/presence_provider.dart';
import '../providers/contacts_provider.dart';
import '../../domain/entities/platform_user.dart';
import '../../../group/data/repositories/group_repository_impl.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool _isLoading = false;

  void _setLoading(bool value) {
    if (mounted) {
      setState(() {
        _isLoading = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final usersAsync = ref.watch(usersProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          AppStrings.contacts,
          style: AppTextStyles.h2.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          usersAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: c.accent)),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(usersProvider),
            ),
            data: (users) {
              final presence = ref.watch(presenceMapProvider);
              final others = users
                  .where((u) => u.id != currentUserId)
                  .map((u) {
                    final live = presence[u.id];
                    return live != null ? u.copyWith(onlineStatus: live) : u;
                  })
                  .toList();

              return Column(
                children: [
                  if (others.isNotEmpty)
                    _CreateGroupTile(contacts: others, onLoading: _setLoading),
                  Expanded(
                    child: others.isEmpty
                        ? const EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No contacts found',
                            subtitle: 'Other users on Slink will appear here.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: others.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: c.divider.withValues(alpha: 0.6),
                              indent: 72,
                            ),
                            itemBuilder: (_, i) => _ContactTile(user: others[i]),
                          ),
                  ),
                ],
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(color: c.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateGroupTile extends ConsumerWidget {
  final List<PlatformUser> contacts;
  final Function(bool) onLoading;
  const _CreateGroupTile({required this.contacts, required this.onLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCreateGroupBottomSheet(context, ref),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: c.accent.withValues(alpha: isDark ? 0.2 : 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: isDark ? 0.08 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.accent, c.accentLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Group Chat',
                        style: AppTextStyles.username.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chat with multiple friends together',
                        style: AppTextStyles.bodySmall.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: c.textMuted, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateGroupBottomSheet(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final selectedUserIds = <String>{};
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (statefulContext, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                    const SizedBox(height: 16),
                    Text(
                      'New Group',
                      style: AppTextStyles.h3.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Group Name',
                          hintText: 'e.g. Weekend Trip',
                          prefixIcon: Icon(Icons.group_rounded, color: c.accent),
                          fillColor: c.inputBackground,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a group name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Members (${selectedUserIds.length})',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final user = contacts[index];
                          final isSelected = selectedUserIds.contains(user.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              user.username,
                              style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
                            ),
                            secondary: AvatarWidget(name: user.username, radius: 18),
                            value: isSelected,
                            activeColor: c.accent,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedUserIds.add(user.id);
                                } else {
                                  selectedUserIds.remove(user.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedUserIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please select at least one member'),
                                backgroundColor: c.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(bottomSheetContext);
                          onLoading(true);

                          try {
                            final groupRepo = ref.read(groupRepositoryProvider);
                            final currentUserId = ref.read(currentUserIdProvider);
                            final allMemberIds = {currentUserId, ...selectedUserIds}.toList();

                            final groupTitle = titleController.text.trim();
                            final chatId = await groupRepo.createGroup(
                              title: groupTitle,
                              memberIds: allMemberIds,
                            );

                            onLoading(false);

                            if (context.mounted) {
                              context.push(
                                Routes.chatPath(chatId),
                                extra: {
                                  'recipientId': chatId,
                                  'recipientName': groupTitle,
                                  'recipientStatus': 'ONLINE',
                                  'isGroup': 1,
                                  'groupTitle': groupTitle,
                                },
                              );
                            }
                          } catch (e) {
                            onLoading(false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(NetworkException.parseError(e)),
                                  backgroundColor: c.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: Text('Create Group', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ContactTile extends ConsumerWidget {
  final PlatformUser user;
  const _ContactTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final isOnline = user.onlineStatus == OnlineStatus.online;

    return InkWell(
      onTap: () => _openChat(context, ref),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                AvatarWidget(name: user.username, radius: 26),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: OnlineBadge(
                    isOnline: isOnline,
                    size: 13,
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
                color: c.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, color: c.accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    try {
      final chatId = await ref.read(chatRepositoryProvider).startChat(user.id);
      if (context.mounted) {
        context.push(Routes.chatPath(chatId), extra: {
          'recipientId': user.id,
          'recipientName': user.username,
          'recipientStatus': user.onlineStatus.name.toUpperCase(),
        });
      }
    } catch (e) {
      if (context.mounted) {
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
  }
}
