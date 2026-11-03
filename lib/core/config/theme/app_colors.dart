import 'package:flutter/material.dart';

/// Theme-aware colour palette.
/// Usage: `AppColors.of(context).accent`
class AppColors {
  final Brightness brightness;
  const AppColors._(this.brightness);

  factory AppColors.of(BuildContext context) =>
      AppColors._(Theme.of(context).brightness);

  bool get _isLight => brightness == Brightness.light;

  // ─── Static brand colours ───────────────────────────────────────
  static const Color primaryBrand = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color sentGradientStart = Color(0xFF6C5CE7);
  static const Color sentGradientEnd = Color(0xFF8070FF);
  static const Color coral = Color(0xFFFF5C6A);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Backgrounds ────────────────────────────────────────────────
  Color get background =>
      _isLight ? const Color(0xFFF6F8FC) : const Color(0xFF0F1115);
  Color get surface =>
      _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF16191E);
  Color get surfaceVariant =>
      _isLight ? const Color(0xFFEEF1F6) : const Color(0xFF1E2228);
  Color get cardBackground =>
      _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF16191E);
  Color get appBarBackground =>
      _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF16191E);
  Color get searchBarBackground =>
      _isLight ? const Color(0xFFEEF1F6) : const Color(0xFF22262E);

  // ─── Accent ─────────────────────────────────────────────────────
  Color get accent =>
      _isLight ? const Color(0xFF6C5CE7) : const Color(0xFF7C6CFF);
  Color get accentLight =>
      _isLight ? const Color(0xFFA29BFE) : const Color(0xFF9B8FFF);
  Color get neon =>
      _isLight ? const Color(0xFF6C5CE7) : const Color(0xFF7C5CFF);

  // ─── Chat bubbles ────────────────────────────────────────────────
  Color get sentMessage => accent;
  Color get receivedMessage =>
      _isLight ? const Color(0xFFF0F2F6) : const Color(0xFF1E2228);
  Color get receivedMessageEdge =>
      _isLight ? const Color(0xFFE8ECF2) : const Color(0xFF181B20);
  Color get sentMessageText => white;
  Color get receivedMessageText =>
      _isLight ? const Color(0xFF1A1D26) : const Color(0xFFEFF1F5);

  // ─── Text ────────────────────────────────────────────────────────
  Color get textPrimary =>
      _isLight ? const Color(0xFF1A1D26) : const Color(0xFFF3F4F6);
  Color get textSecondary =>
      _isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  Color get textMuted =>
      _isLight ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  // ─── Status ──────────────────────────────────────────────────────
  Color get online =>
      _isLight ? const Color(0xFF10B981) : const Color(0xFF2EE6A7);
  Color get offline =>
      _isLight ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get error =>
      _isLight ? const Color(0xFFEF4444) : const Color(0xFFFF6B6B);

  // ─── Misc ────────────────────────────────────────────────────────
  Color get divider =>
      _isLight ? const Color(0xFFE5E7EB) : const Color(0xFF252930);
  Color get shadowLight =>
      _isLight ? const Color(0x1A000000) : const Color(0x33FFFFFF);
  Color get shadowDark =>
      _isLight ? const Color(0x26000000) : const Color(0x66000000);
  Color get inputBackground =>
      _isLight ? const Color(0xFFF3F4F6) : const Color(0xFF1A1D24);
}

// ─── Gradients ───────────────────────────────────────────────────────────────
class AppGradients {
  static LinearGradient backgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [const Color(0xFF0D0E12), const Color(0xFF16191E)]
          : [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const LinearGradient sentMessageGradient = LinearGradient(
    colors: [AppColors.sentGradientStart, AppColors.sentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient receivedMessageGradient(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      colors: [c.receivedMessage, c.receivedMessageEdge],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient homeGradient(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      colors: [c.appBarBackground, c.background],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
