class AuthResponse {
  final String token;
  final String userId;
  final String username;

  const AuthResponse({
    required this.token,
    required this.userId,
    required this.username,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] ?? '',
        userId: json['userId']?.toString() ?? '',
        username: json['username'] ?? '',
      );
}

