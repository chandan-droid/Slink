
class RegisterRequest {
  final String phoneNumber;
  final String username;
  final String email;
  final String password;

  RegisterRequest({
    required this.phoneNumber,
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'username': username,
      'email': email,
      'password': password,
    };
  }
}