import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

class OnlineBadge extends StatelessWidget {
  final bool isOnline;
  final double size;
  final bool showBorder;

  const OnlineBadge({
    super.key,
    required this.isOnline,
    this.size = 10,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? c.online : c.offline,
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: c.surface, width: 2) : null,
        boxShadow: isOnline
            ? [BoxShadow(color: c.online.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
            : null,
      ),
    );
  }
}

