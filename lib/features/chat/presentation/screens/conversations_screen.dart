import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_strings.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/online_badge.dart';
import '../providers/conversation_list_provider.dart';
import '../../domain/entities/conversation.dart';

abstract class ConversationItem {
  DateTime get latestActivity;
}

class IndividualConversationItem implements ConversationItem {
  final Conversation conversation;
  IndividualConversationItem(this.conversation);

  @override
  DateTime get latestActivity => conversation.lastMessageTime ?? DateTime(0);
}

class CommunityGroupItem implements ConversationItem {
  final String communityId;
  final String communityName;
  final List<Conversation> conversations;

  CommunityGroupItem({
    required this.communityId,
    required this.communityName,
    required this.conversations,
  });

  @override
  DateTime get latestActivity {
    DateTime latest = DateTime(0);
    for (var c in conversations) {
      final time = c.lastMessageTime;
      if (time != null && time.isAfter(latest)) {
        latest = time;
      }
    }
    return latest;
  }
}

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final Map<String, bool> _collapsedCommunities = {};

  List<ConversationItem> _buildConversationItems(List<Conversation> convos) {
    final List<ConversationItem> items = [];
    final Map<String, List<Conversation>> communityGroups = {};
    final Map<String, String> communityNames = {};

    for (var convo in convos) {
      if (convo.isGroup == 2 && convo.communityId != null) {
        final cid = convo.communityId!;
        communityGroups.putIfAbsent(cid, () => []).add(convo);
        if (convo.communityName != null) {
          communityNames[cid] = convo.communityName!;
        }
      } else {
        items.add(IndividualConversationItem(convo));
      }
    }

    communityGroups.forEach((cid, groupConvos) {
      groupConvos.sort((a, b) => (b.lastMessageTime ?? DateTime(0))
          .compareTo(a.lastMessageTime ?? DateTime(0)));
      items.add(CommunityGroupItem(
        communityId: cid,
        communityName: communityNames[cid] ?? 'Community',
        conversations: groupConvos,
      ));
    });

    items.sort((a, b) => b.latestActivity.compareTo(a.latestActivity));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final convos = ref.watch(conversationListProvider);
    final items = _buildConversationItems(convos);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.appBarBackground,
        title: Text(AppStrings.chats,
            style: AppTextStyles.h2.copyWith(color: c.textPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: c.accent,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                tooltip: 'New chat',
                onPressed: () => context.push(Routes.contacts),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.homeGradient(context)),
        child: Column(
          children: [
            _SearchBar(),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: AppStrings.noChatsYet,
                      subtitle: AppStrings.startChatting,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: c.divider.withValues(alpha: 0.5),
                        indent: 84,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is IndividualConversationItem) {
                          return _buildIndividualTile(item.conversation, c);
                        } else if (item is CommunityGroupItem) {
                          return _buildCommunityGroup(item, c);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualTile(Conversation convo, AppColors c) {
    final isGroup = convo.isGroup == 1;
    final name = isGroup ? (convo.groupTitle ?? convo.participantName) : convo.participantName;

    return InkWell(
      onTap: () => context.push(
        Routes.chatPath(convo.chatId),
        extra: {
          'recipientId': convo.participantId,
          'recipientName': name,
          'recipientStatus': convo.isOnline ? 'ONLINE' : 'OFFLINE',
          'isGroup': convo.isGroup,
          'communityId': convo.communityId,
          'communityName': convo.communityName,
          'groupTitle': convo.groupTitle,
        },
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (isGroup)
              CircleAvatar(
                radius: 28,
                backgroundColor: c.accent.withValues(alpha: 0.15),
                child: Icon(Icons.groups, color: c.accent, size: 28),
              )
            else
              Stack(
                children: [
                  AvatarWidget(name: convo.participantName, radius: 28),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: OnlineBadge(
                        isOnline: convo.isOnline, size: 14, showBorder: true),
                  ),
                ],
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.username.copyWith(color: c.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    convo.lastMessage ?? 'Tap to chat',
                    style: AppTextStyles.bodySmall.copyWith(color: c.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTrailingInfo(convo.lastMessageTime, convo.unreadCount, c),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityGroup(CommunityGroupItem item, AppColors c) {
    final isCollapsed = _collapsedCommunities[item.communityId] ?? false;
    final totalUnread = item.conversations.fold<int>(
      0, (sum, convo) => sum + convo.unreadCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _collapsedCommunities[item.communityId] = !isCollapsed;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.cardBackground.withValues(alpha: 0.25),
              border: Border(
                bottom: BorderSide(color: c.divider.withValues(alpha: 0.3), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.accent.withValues(alpha: 0.15),
                  child: Text(
                    item.communityName.isNotEmpty
                        ? item.communityName[0].toUpperCase()
                        : 'C',
                    style: AppTextStyles.h3.copyWith(
                      color: c.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.communityName,
                              style: AppTextStyles.username.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'COMMUNITY',
                              style: TextStyle(
                                color: c.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.conversations.length} rooms',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: c.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalUnread > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalUnread',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down,
                  color: c.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isCollapsed)
          ...item.conversations.map((convo) => _buildCommunityRoomTile(convo, c)),
      ],
    );
  }

  Widget _buildCommunityRoomTile(Conversation convo, AppColors c) {
    final title = convo.groupTitle ?? 'Room';

    return InkWell(
      onTap: () => context.push(
        Routes.chatPath(convo.chatId),
        extra: {
          'recipientId': convo.participantId,
          'recipientName': convo.communityName ?? 'Community',
          'recipientStatus': 'ONLINE',
          'isGroup': convo.isGroup,
          'communityId': convo.communityId,
          'communityName': convo.communityName,
          'groupTitle': convo.groupTitle,
        },
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 36, right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.divider.withValues(alpha: 0.1), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.tag, color: c.accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '# $title',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    convo.lastMessage ?? 'Tap to chat',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: c.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTrailingInfo(convo.lastMessageTime, convo.unreadCount, c),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingInfo(DateTime? lastMessageTime, int unreadCount, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lastMessageTime != null)
          Text(
            SlinkDateUtils.formatTime(lastMessageTime),
            style: AppTextStyles.labelSmall.copyWith(color: c.textMuted),
          ),
        if (unreadCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: c.accent, borderRadius: BorderRadius.circular(12)),
            child: Text(
              '$unreadCount',
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            color: c.searchBarBackground,
            borderRadius: BorderRadius.circular(25)),
        child: TextField(
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: AppStrings.search,
            hintStyle: TextStyle(color: c.textMuted),
            prefixIcon: Icon(Icons.search, color: c.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
