class GroupDto {
  final String chatId;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<GroupMemberDto> members;

  const GroupDto({
    required this.chatId,
    required this.name,
    this.description,
    this.imageUrl,
    this.members = const [],
  });

  factory GroupDto.fromJson(Map<String, dynamic> json) => GroupDto(
        chatId: json['chatId']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        imageUrl: json['imageUrl'],
        members: (json['members'] as List? ?? [])
            .map((e) => GroupMemberDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GroupMemberDto {
  final String userId;
  final String username;
  final String role; // ADMIN | MEMBER

  const GroupMemberDto(
      {required this.userId, required this.username, required this.role});

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) => GroupMemberDto(
        userId: json['userId']?.toString() ?? '',
        username: json['username'] ?? '',
        role: json['role'] ?? 'MEMBER',
      );
}

