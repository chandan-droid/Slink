import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onTyping;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onTyping,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    if (hasText) {
      widget.onTyping();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.add,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                // TODO: Show attachment options
              },
            ),
          ),
          const SizedBox(width: 8),
          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: AppStrings.typeMessage,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      // TODO: Show emoji picker
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: _hasText ? AppGradients.primaryGradient : null,
              color: _hasText ? null : AppColors.inputBackground,
              shape: BoxShape.circle,
              boxShadow: _hasText
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hasText ? widget.onSend : null,
                borderRadius: BorderRadius.circular(24),
                child: Icon(
                  Icons.send_rounded,
                  color: _hasText ? Colors.white : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

