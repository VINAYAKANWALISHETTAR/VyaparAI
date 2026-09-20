class RegisterRequest {
  final String name;
  final String email;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
      };
}
