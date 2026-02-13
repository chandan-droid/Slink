enum Status {
  online,
  offline,
  away,
}

class UserStatus {
  final String userId;
  final String username;
  final Status status;

  UserStatus({
    required this.userId,
    required this.username,
    this.status = Status.offline,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      status: _parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'status': status.name.toUpperCase(),
    };
  }

  static Status _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ONLINE':
        return Status.online;
      case 'AWAY':
        return Status.away;
      default:
        return Status.offline;
    }
  }

  UserStatus copyWith({
    String? userId,
    String? username,
    Status? status,
  }) {
    return UserStatus(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      status: status ?? this.status,
    );
  }
}

