import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/message_status_icon.dart';
import '../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final textColor = isMe ? c.sentMessageText : c.receivedMessageText;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isMe ? 48 : 12,
          right: isMe ? 12 : 48,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isMe
                ? AppGradients.sentMessageGradient
                : AppGradients.receivedMessageGradient(context),
            border: !isMe && isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.8)
                : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: isMe
                    ? c.accent.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: AppTextStyles.chatMessage.copyWith(
                  color: textColor,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    SlinkDateUtils.formatTime(message.createdAt),
                    style: AppTextStyles.chatTime.copyWith(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.8)
                          : c.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    MessageStatusIconWidget(status: _toIconStatus(message.status)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  MessageStatusIcon _toIconStatus(MessageStatus s) {
    switch (s) {
      case MessageStatus.read:
        return MessageStatusIcon.read;
      case MessageStatus.delivered:
        return MessageStatusIcon.delivered;
      case MessageStatus.sending:
        return MessageStatusIcon.sending;
      default:
        return MessageStatusIcon.sent;
    }
  }
}
