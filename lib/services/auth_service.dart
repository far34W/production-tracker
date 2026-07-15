// lib/services/auth_service.dart
//
// Handles all authentication HTTP calls.
// Currently uses a simulated delay so the UI works without a backend.
//
// ── HOW TO CONNECT TO LARAVEL ─────────────────────────────────────────────
//
// 1. Add `dio` or `http` to pubspec.yaml.
// 2. Replace the `_simulateLogin` block inside `login()` with a real call:
//
//    final response = await _dio.post(
//      '$_baseUrl/api/auth/login',
//      data: {'email': email, 'password': password},
//    );
//    return User.fromJson(response.data['user'] as Map<String, dynamic>)
//        .copyWith(token: response.data['token'] as String);
//
// 3. Store the Bearer token and attach it to every future request:
//    _dio.options.headers['Authorization'] = 'Bearer ${user.token}';
//
// ─────────────────────────────────────────────────────────────────────────────

import '../models/user.dart';

/// Thrown when credentials are wrong or the server rejects the request.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Replace with your actual Laravel base URL when ready.
  // ignore: unused_field
  static const String _baseUrl = 'https://your-laravel-app.com';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Attempts to authenticate [email] / [password].
  /// Returns a [User] on success, throws [AuthException] on failure.
  Future<User> login(String email, String password) async {
    // ── SIMULATION (remove when connecting to Laravel) ──────────────────────
    await Future.delayed(const Duration(milliseconds: 1400));

    // Simulate a bad-credential error for any unknown email
    if (email != 'admin@example.com' || password != 'password') {
      throw const AuthException(
        'Invalid email or password. Please try again.',
      );
    }

    return User(
      id: '1',
      name: 'Admin User',
      email: email,
      role: 'admin',
      token: 'simulated_bearer_token_abc123',
    );
    // ── END SIMULATION ────────────────────────────────────────────────────────

    // ── REAL LARAVEL IMPLEMENTATION (uncomment when ready) ───────────────────
    // try {
    //   final response = await http.post(
    //     Uri.parse('$_baseUrl/api/auth/login'),
    //     headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    //     body: jsonEncode({'email': email, 'password': password}),
    //   );
    //   final body = jsonDecode(response.body) as Map<String, dynamic>;
    //   if (response.statusCode == 200) {
    //     return User.fromJson(body['user']).copyWith(token: body['token']);
    //   }
    //   throw AuthException(body['message'] ?? 'Login failed');
    // } on SocketException {
    //   throw const AuthException('No internet connection.');
    // }
    // ─────────────────────────────────────────────────────────────────────────
  }

  /// Revokes the session token on the server (noop in simulation).
  Future<void> logout(String? token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Real: await http.post('$_baseUrl/api/auth/logout',
    //   headers: {'Authorization': 'Bearer $token'});
  }
}
