class PresenceDto {
  final String userId;
  final String status;
  final String? lastSeen;

  const PresenceDto({required this.userId, required this.status, this.lastSeen});

  factory PresenceDto.fromJson(Map<String, dynamic> json) => PresenceDto(
        userId: json['userId']?.toString() ?? '',
        status: json['status'] ?? 'OFFLINE',
        lastSeen: json['lastSeen'],
      );
}

