import 'package:flutter/material.dart';
import '../config/theme/app_text_styles.dart';

/// Letter-based avatar with distinct deterministic gradients per username.
class AvatarWidget extends StatelessWidget {
  final String name;
  final double radius;
  final double? fontSize;

  const AvatarWidget({
    super.key,
    required this.name,
    this.radius = 24,
    this.fontSize,
  });

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF6C5CE7), Color(0xFF8E7CFF)], // Indigo / Brand
    [Color(0xFF00B4D8), Color(0xFF0077B6)], // Ocean Cyan
    [Color(0xFF10B981), Color(0xFF059669)], // Emerald Green
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)], // Sunset Coral
    [Color(0xFFF59E0B), Color(0xFFD97706)], // Warm Amber
    [Color(0xFFEC4899), Color(0xFFDB2777)], // Rose Pink
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Electric Blue
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Deep Violet
    [Color(0xFF14B8A6), Color(0xFF0F766E)], // Teal
  ];

  List<Color> get _gradientColors {
    if (name.isEmpty) return _avatarGradients[0];
    final hash = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return _avatarGradients[hash % _avatarGradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final colors = _gradientColors;
    final fSize = fontSize ?? (radius * 0.85);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontSize: fSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
