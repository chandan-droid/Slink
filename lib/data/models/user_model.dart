enum OnlineStatus { online, offline, away }

class UserModel {
  final String id;
  final String username;
  final String? phoneNumber;
  final String? email;
  final OnlineStatus onlineStatus;
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    required this.username,
    this.phoneNumber,
    this.email,
    this.onlineStatus = OnlineStatus.offline,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      onlineStatus: _parseOnlineStatus(json['onlineStatus']),
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phoneNumber': phoneNumber,
      'email': email,
      'onlineStatus': onlineStatus.name.toUpperCase(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  static OnlineStatus _parseOnlineStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ONLINE':
        return OnlineStatus.online;
      case 'AWAY':
        return OnlineStatus.away;
      default:
        return OnlineStatus.offline;
    }
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? phoneNumber,
    String? email,
    OnlineStatus? onlineStatus,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

