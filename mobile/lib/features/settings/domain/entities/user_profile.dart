/// GET /users/me (docs/08_API.md §12).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.email,
    required this.name,
    required this.locale,
    required this.defaultCurrency,
  });

  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final String locale;
  final String defaultCurrency;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      locale: json['locale'] as String,
      defaultCurrency: json['defaultCurrency'] as String,
    );
  }
}
