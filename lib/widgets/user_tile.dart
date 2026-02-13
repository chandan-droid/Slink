import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../data/models/user_model.dart';
import 'online_indicator.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final bool isTyping;
  final VoidCallback onTap;

  const UserTile({
    super.key,
    required this.user,
    this.isTyping = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: OnlineIndicator(
                        isOnline: user.onlineStatus == OnlineStatus.online,
                        size: 14,
                        showBorder: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: AppTextStyles.username,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (isTyping)
                        Row(
                          children: [
                            Text(
                              AppStrings.typing,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _buildTypingAnimation(),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              user.onlineStatus == OnlineStatus.online
                                  ? Icons.circle
                                  : Icons.access_time,
                              size: 12,
                              color: user.onlineStatus == OnlineStatus.online
                                  ? AppColors.online
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.onlineStatus == OnlineStatus.online
                                  ? AppStrings.online
                                  : AppStrings.offline,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: user.onlineStatus == OnlineStatus.online
                                    ? AppColors.online
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Arrow icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingAnimation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 200)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

