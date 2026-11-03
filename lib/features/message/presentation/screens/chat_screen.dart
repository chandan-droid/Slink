import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_strings.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/online_badge.dart';
import '../../../../core/widgets/typing_indicator.dart';
import '../../../../core/websocket/stomp_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/conversation_list_provider.dart';
import '../../../contacts/domain/entities/platform_user.dart';
import '../../../presence/presentation/providers/presence_provider.dart';
import '../providers/message_list_provider.dart';
import '../providers/typing_provider.dart';
import '../widgets/date_separator.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/offline_banner.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../../group/data/repositories/group_repository_impl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final String recipientStatus;

  final int isGroup;
  final String? communityId;
  final String? communityName;
  final String? groupTitle;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientStatus,
    this.isGroup = 0,
    this.communityId,
    this.communityName,
    this.groupTitle,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;
  int _lastCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.setActiveChat(widget.chatId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationListProvider.notifier)
        ..upsertFromOpen(
          widget.chatId,
          widget.recipientId,
          widget.recipientName,
          isGroup: widget.isGroup,
          communityId: widget.communityId,
          communityName: widget.communityName,
          groupTitle: widget.groupTitle,
        )
        ..clearUnread(widget.chatId);
    });
  }

  @override
  void dispose() {
    PushNotificationService.instance.setActiveChat(null);
    _scroll.dispose();
    _input.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      ref.read(stompServiceProvider).sendTyping(
            chatId: widget.chatId,
            recipientId: widget.recipientId,
          );
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _isTyping = false;
    });
  }

  void _sendMessage() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref
        .read(messageListProvider(widget.chatId).notifier)
        .send(text, widget.recipientId);
    _scrollToBottom();
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() {
        _isLoading = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ChatBody(
          chatId: widget.chatId,
          recipientId: widget.recipientId,
          recipientName: widget.recipientName,
          recipientStatus: widget.recipientStatus,
          scroll: _scroll,
          input: _input,
          onSend: _sendMessage,
          onTyping: _handleTyping,
          lastCount: _lastCount,
          onNewMessages: (count) => _lastCount = count,
          scrollToBottom: _scrollToBottom,
          onLoading: _setLoading,
        ),
        if (_isLoading) ...[
          const ModalBarrier(
            dismissible: false,
            color: Colors.black54,
          ),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }
}

class _ChatBody extends ConsumerWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final String recipientStatus;
  final ScrollController scroll;
  final TextEditingController input;
  final VoidCallback onSend;
  final VoidCallback onTyping;
  final int lastCount;
  final void Function(int) onNewMessages;
  final VoidCallback scrollToBottom;
  final Function(bool) onLoading;

  const _ChatBody({
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientStatus,
    required this.scroll,
    required this.input,
    required this.onSend,
    required this.onTyping,
    required this.lastCount,
    required this.onNewMessages,
    required this.scrollToBottom,
    required this.onLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final messagesAsync = ref.watch(messageListProvider(chatId));
    final wsConnAsync = ref.watch(wsConnectionProvider);
    final isConnected = wsConnAsync.value ?? ref.watch(stompServiceProvider).isConnected;
    final presence = ref.watch(presenceMapProvider);
    final isOnline = presence[recipientId] == OnlineStatus.online ||
        recipientStatus.toUpperCase() == 'ONLINE';
    final typingMap = ref.watch(typingProvider);
    final isTyping = typingMap[recipientId] ?? false;

    messagesAsync.whenData((msgs) {
      if (msgs.length != lastCount) {
        onNewMessages(msgs.length);
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: c.background,
      appBar: _AppBar(
        chatId: chatId,
        recipientName: recipientName,
        recipientId: recipientId,
        isOnline: isOnline,
        isTyping: isTyping,
        onLoading: onLoading,
      ),
      body: Column(
        children: [
          if (!isConnected) const OfflineBanner(),
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: c.accent)),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(messageListProvider(chatId).notifier).reload(),
              ),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No messages yet',
                        subtitle: 'Send a message to start chatting with $recipientName',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scroll,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final isMe = msg.senderId == currentUserId;
                    final showDate = i == 0 ||
                        !SlinkDateUtils.isSameDay(
                            msgs[i - 1].createdAt, msg.createdAt);
                    return Column(
                      children: [
                        if (showDate) DateSeparator(date: msg.createdAt),
                        MessageBubble(message: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const TypingIndicator(),
              ),
            ),
          MessageInputBar(
            controller: input,
            onSend: onSend,
            onTyping: onTyping,
          ),
        ],
      ),
    );
  }
}

class _AppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String chatId;
  final String recipientName;
  final String recipientId;
  final bool isOnline;
  final bool isTyping;
  final Function(bool) onLoading;

  const _AppBar({
    required this.chatId,
    required this.recipientName,
    required this.recipientId,
    required this.isOnline,
    required this.isTyping,
    required this.onLoading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return AppBar(
      elevation: 0,
      backgroundColor: c.appBarBackground,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: c.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              AvatarWidget(name: recipientName, radius: 20),
              Positioned(
                right: 0,
                bottom: 0,
                child:
                    OnlineBadge(isOnline: isOnline, size: 12, showBorder: true),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipientName,
                  style: AppTextStyles.h4.copyWith(color: c.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isTyping
                  ? AppStrings.typing
                  : isOnline
                      ? AppStrings.online
                      : AppStrings.offline,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isTyping
                        ? c.accent
                        : isOnline
                            ? c.online
                            : c.textMuted,
                    fontStyle:
                        isTyping ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (recipientId.isEmpty)
          IconButton(
            icon: Icon(Icons.settings, color: c.textPrimary),
            onPressed: () => _showGroupSettings(context, ref),
          )
        else
          IconButton(
            icon: Icon(Icons.more_vert, color: c.textPrimary),
            onPressed: () {},
          ),
      ],
    );
  }

  void _showGroupSettings(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final currentUserId = ref.read(currentUserIdProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 24),
                Text(
                  recipientName,
                  style: AppTextStyles.h2.copyWith(color: c.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Group Settings',
                  style: AppTextStyles.bodySmall.copyWith(color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(Icons.person_add_outlined, color: c.accent),
                  title: Text('Add Member', style: TextStyle(color: c.textPrimary)),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext); // Close sheet
                    await Future.delayed(Duration.zero);
                    if (context.mounted) {
                      _showAddMemberDialog(context, ref);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: c.error),
                  title: Text('Leave Group', style: TextStyle(color: c.error)),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext); // Close sheet
                    await Future.delayed(Duration.zero);
                    if (context.mounted) {
                      _showLeaveGroupConfirmation(context, ref, currentUserId);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final usersAsync = ref.read(usersProvider);

    usersAsync.whenData((users) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: c.surface,
            title: Text('Add Member', style: AppTextStyles.h2.copyWith(color: c.textPrimary)),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (statefulContext, idx) {
                  final u = users[idx];
                  return ListTile(
                    title: Text(u.username, style: TextStyle(color: c.textPrimary)),
                    trailing: Icon(Icons.add, color: c.accent),
                    onTap: () async {
                      Navigator.pop(dialogContext); // Close contacts list dialog
                      await Future.delayed(Duration.zero);

                      onLoading(true);

                      try {
                        await ref.read(groupRepositoryProvider).addMember(
                          chatId: chatId,
                          userId: u.id,
                        );
                        onLoading(false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${u.username} added successfully!')),
                          );
                        }
                      } catch (e) {
                        onLoading(false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add member: $e')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: TextStyle(color: c.textMuted)),
              ),
            ],
          );
        },
      );
    });
  }

  void _showLeaveGroupConfirmation(BuildContext context, WidgetRef ref, String currentUserId) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: c.surface,
          title: Text('Leave Group?', style: AppTextStyles.h2.copyWith(color: c.textPrimary)),
          content: const Text(
            'Are you sure you want to leave this group? You will no longer receive any updates.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: c.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: c.error),
              onPressed: () async {
                Navigator.pop(dialogContext); // close confirm dialog
                await Future.delayed(Duration.zero);

                onLoading(true);

                try {
                  await ref.read(groupRepositoryProvider).removeMember(
                    chatId: chatId,
                    userId: currentUserId,
                  );
                  onLoading(false);
                  if (context.mounted) {
                    Navigator.pop(context); // pop chat screen itself
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Left group chat successfully!')),
                    );
                  }
                } catch (e) {
                  onLoading(false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to leave group: $e')),
                    );
                  }
                }
              },
              child: const Text('Leave', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
