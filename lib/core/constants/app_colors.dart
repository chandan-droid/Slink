import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);

  // Secondary Colors
  static const Color secondary = Color(0xFF00D9A5);
  static const Color secondaryLight = Color(0xFF5EFFE4);
  static const Color secondaryDark = Color(0xFF00A676);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF16213E);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Status Colors
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color away = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  // Chat Colors
  static const Color sentMessage = Color(0xFF6C63FF);
  static const Color receivedMessage = Color(0xFFE5E7EB);
  static const Color messageText = Color(0xFFFFFFFF);
  static const Color receivedMessageText = Color(0xFF1A1A2E);

  // Other Colors
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x1A000000);
  static const Color shimmer = Color(0xFFE5E7EB);
  static const Color inputBackground = Color(0xFFF3F4F6);
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

