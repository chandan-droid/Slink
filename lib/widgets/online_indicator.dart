import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;
  final bool showBorder;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.size = 10,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.online : AppColors.offline,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: 2)
            : null,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: AppColors.online.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

