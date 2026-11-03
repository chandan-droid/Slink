enum OnlineStatus { online, offline, away }

class PlatformUser {
  final String id;
  final String username;
  final String? phoneNumber;
  final String? email;
  final OnlineStatus onlineStatus;

  const PlatformUser({
    required this.id,
    required this.username,
    this.phoneNumber,
    this.email,
    this.onlineStatus = OnlineStatus.offline,
  });

  static OnlineStatus parseStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'ONLINE':
        return OnlineStatus.online;
      case 'AWAY':
        return OnlineStatus.away;
      default:
        return OnlineStatus.offline;
    }
  }

  PlatformUser copyWith({OnlineStatus? onlineStatus}) => PlatformUser(
        id: id,
        username: username,
        phoneNumber: phoneNumber,
        email: email,
        onlineStatus: onlineStatus ?? this.onlineStatus,
      );

  @override
  bool operator ==(Object other) =>
      other is PlatformUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

