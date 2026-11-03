class Group {
  final String chatId;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<GroupMember> members;

  const Group({
    required this.chatId,
    required this.name,
    this.description,
    this.imageUrl,
    this.members = const [],
  });
}

enum GroupRole { admin, member }

class GroupMember {
  final String userId;
  final String username;
  final GroupRole role;

  const GroupMember(
      {required this.userId,
      required this.username,
      this.role = GroupRole.member});
}

