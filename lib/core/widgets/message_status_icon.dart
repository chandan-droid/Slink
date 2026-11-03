import 'package:flutter/material.dart';

enum MessageStatusIcon { sending, sent, delivered, read }

class MessageStatusIconWidget extends StatelessWidget {
  final MessageStatusIcon status;
  const MessageStatusIconWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatusIcon.read:
        return Icon(Icons.done_all, size: 16, color: Colors.white.withValues(alpha: 0.9));
      case MessageStatusIcon.delivered:
        return Icon(Icons.done_all, size: 16, color: Colors.white.withValues(alpha: 0.7));
      case MessageStatusIcon.sent:
        return Icon(Icons.done, size: 16, color: Colors.white.withValues(alpha: 0.6));
      case MessageStatusIcon.sending:
        return Icon(Icons.access_time, size: 14, color: Colors.white.withValues(alpha: 0.5));
    }
  }
}

