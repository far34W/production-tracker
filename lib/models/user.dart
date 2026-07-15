// lib/models/user.dart
//
// Represents the authenticated user returned by the API.
// All fields are kept generic so swapping the backend (Laravel, etc.)
// only requires changing AuthService — nothing else.

class User {
  final String id;
  final String name;
  final String email;
  final String? role;
  final String? token; // Bearer token from Laravel Sanctum / Passport

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.token,
  });

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String?,
        token: json['token'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'token': token,
      };

  // ── SharedPreferences helpers ─────────────────────────────────────────────
  // Store as a flat map so we don't need json_serializable.

  factory User.fromPrefs(Map<String, String?> prefs) => User(
        id: prefs['user_id'] ?? '',
        name: prefs['user_name'] ?? '',
        email: prefs['user_email'] ?? '',
        role: prefs['user_role'],
        token: prefs['user_token'],
      );

  Map<String, String> toPrefs() => {
        'user_id': id,
        'user_name': name,
        'user_email': email,
        if (role != null) 'user_role': role!,
        if (token != null) 'user_token': token!,
      };

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
