class Community {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final DateTime? createdAt;
  final bool isPublic;
  final int memberCount;

  const Community({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    this.createdAt,
    this.isPublic = true,
    this.memberCount = 0,
  });

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? ownerId,
    DateTime? createdAt,
    bool? isPublic,
    int? memberCount,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}

