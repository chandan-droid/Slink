class RegisterRequest {
  final String phoneNumber;
  final String username;
  final String email;
  final String password;

  const RegisterRequest({
    required this.phoneNumber,
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'username': username,
        'email': email,
        'password': password,
      };
}

