import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/chat_input.dart';
import '../../widgets/online_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel recipient;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipient,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadChatHistory();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    await context.read<ChatProvider>().fetchChatHistory(widget.chatId);
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position.maxScrollExtent;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (animated) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    });
  }

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      context.read<ChatProvider>().sendTypingIndicator(
        widget.recipient.id,
        widget.recipient.username,
      );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _isTyping = false;
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    context.read<ChatProvider>().sendMessage(
      content: content,
      recipientId: widget.recipient.id,
      senderId: authProvider.currentUser!.id,
      recipientName: widget.recipient.username,
      chatId: widget.chatId,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Consumer2<AuthProvider, ChatProvider>(
        builder: (context, auth, chat, _) {
          // 🔄 Scroll to bottom when a new message arrives
          if (chat.messages.length != _lastMessageCount) {
            _lastMessageCount = chat.messages.length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }

          return Column(
            children: [
              Expanded(child: _buildMessageList(auth, chat)),
              _buildTypingIndicator(chat),
              ChatInput(
                controller: _messageController,
                onSend: _sendMessage,
                onTyping: _handleTyping,
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () {
          context.read<ChatProvider>().clearMessages();
          Navigator.of(context).pop();
        },
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  widget.recipient.username[0].toUpperCase(),
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: OnlineIndicator(
                  isOnline: widget.recipient.onlineStatus == OnlineStatus.online,
                  size: 12,
                  showBorder: true,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipient.username,
                  style: AppTextStyles.h4,
                  overflow: TextOverflow.ellipsis,
                ),
                Consumer<ChatProvider>(
                  builder: (context, chat, _) {
                    final isTyping = chat.isUserTyping(widget.recipient.id);
                    if (isTyping) {
                      return Text(
                        AppStrings.typing,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return Text(
                      widget.recipient.onlineStatus == OnlineStatus.online
                          ? AppStrings.online
                          : AppStrings.offline,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: widget.recipient.onlineStatus == OnlineStatus.online
                            ? AppColors.online
                            : AppColors.textMuted,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          onPressed: () {
            // TODO: Show options menu
          },
        ),
      ],
    );
  }

  Widget _buildMessageList(AuthProvider auth, ChatProvider chat) {
    if (chat.isLoading && chat.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (chat.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noMessages,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.startConversation,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        final isMe = message.senderId == auth.currentUser?.id;

        final showDateSeparator = index == 0 ||
            !_isSameDay(
              chat.messages[index - 1].createdAt,
              message.createdAt,
            );

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.createdAt),
            MessageBubble(
              message: message,
              isMe: isMe,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator(ChatProvider chat) {
    final isTyping = chat.isUserTyping(widget.recipient.id);
    if (!isTyping) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.receivedMessage,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingDot(0),
            const SizedBox(width: 4),
            _buildTypingDot(1),
            const SizedBox(width: 4),
            _buildTypingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 150)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.6 + (0.4 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return AppStrings.today;
    } else if (messageDate == yesterday) {
      return AppStrings.yesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Place this inside `_ChatScreenState` (not top-level), e.g. below `_buildMessageList`
  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: AppTextStyles.labelSmall,
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }

}
