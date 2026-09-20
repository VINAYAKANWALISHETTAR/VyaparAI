/// Model representing the authenticated user's profile returned by /users/me.
class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String businessName;
  final String phone;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.businessName = '',
    this.phone = '',
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}
