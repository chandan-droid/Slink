class CommunityDto {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final DateTime? createdAt;
  final bool isPublic;
  final int memberCount;

  const CommunityDto({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    this.createdAt,
    this.isPublic = true,
    this.memberCount = 0,
  });

  factory CommunityDto.fromJson(Map<String, dynamic> json) => CommunityDto(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        avatarUrl: json['avatarUrl'],
        ownerId: json['ownerId']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        isPublic: json['isPublic'] != false,
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      );
}

