class UserSummaryDto {
  final String id;
  final String username;
  final String? phoneNumber;
  final String? email;
  final String onlineStatus;

  const UserSummaryDto({
    required this.id,
    required this.username,
    this.phoneNumber,
    this.email,
    this.onlineStatus = 'OFFLINE',
  });

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) => UserSummaryDto(
        id: json['id']?.toString() ?? '',
        username: json['username'] ?? '',
        phoneNumber: json['phoneNumber'],
        email: json['email'],
        onlineStatus: json['onlineStatus'] ?? 'OFFLINE',
      );
}

