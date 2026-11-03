class Conversation {
  final String chatId;
  final String participantId;
  final String participantName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  final int isGroup; // 0 = DIRECT, 1 = Standalone GROUP, 2 = COMMUNITY chat
  final String? communityId;
  final String? communityName;
  final String? groupTitle;

  const Conversation({
    required this.chatId,
    required this.participantId,
    required this.participantName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = 0,
    this.communityId,
    this.communityName,
    this.groupTitle,
  });

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    int? isGroup,
    String? communityId,
    String? communityName,
    String? groupTitle,
  }) =>
      Conversation(
        chatId: chatId,
        participantId: participantId,
        participantName: participantName,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        unreadCount: unreadCount ?? this.unreadCount,
        isOnline: isOnline ?? this.isOnline,
        isGroup: isGroup ?? this.isGroup,
        communityId: communityId ?? this.communityId,
        communityName: communityName ?? this.communityName,
        groupTitle: groupTitle ?? this.groupTitle,
      );
}

