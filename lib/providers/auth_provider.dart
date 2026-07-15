// lib/providers/auth_provider.dart
//
// Central authentication state for the entire app.
// Consumed by:
//   • AuthGate        → decides which screen to show
//   • LoginScreen     → calls login(), reads isLoading / errorMessage
//   • AppShell / Menu → calls logout(), reads currentUser
//
// Session is persisted via SharedPreferences so the user stays logged
// in across app restarts.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Keys used in SharedPreferences
const _kIsLoggedIn  = 'auth_is_logged_in';
const _kUserId      = 'user_id';
const _kUserName    = 'user_name';
const _kUserEmail   = 'user_email';
const _kUserRole    = 'user_role';
const _kUserToken   = 'user_token';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  // ── State ─────────────────────────────────────────────────────────────────

  User?   _currentUser;
  bool    _isLoading        = false;
  bool    _isCheckingSession = true; // true while reading SharedPreferences
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────

  User?   get currentUser        => _currentUser;
  bool    get isAuthenticated     => _currentUser != null;
  bool    get isLoading          => _isLoading;
  bool    get isCheckingSession  => _isCheckingSession;
  String? get errorMessage       => _errorMessage;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Call once from main() / MultiProvider create.
  /// Restores a persisted session so the user isn't forced to log in
  /// every time the app is restarted.
  Future<void> tryRestoreSession() async {
    _isCheckingSession = true;
    notifyListeners();

    try {
      final prefs       = await SharedPreferences.getInstance();
      final isLoggedIn  = prefs.getBool(_kIsLoggedIn) ?? false;

      if (isLoggedIn) {
        final user = User.fromPrefs({
          'user_id':    prefs.getString(_kUserId),
          'user_name':  prefs.getString(_kUserName),
          'user_email': prefs.getString(_kUserEmail),
          'user_role':  prefs.getString(_kUserRole),
          'user_token': prefs.getString(_kUserToken),
        });

        // Only restore if we have enough data to be useful
        if (user.id.isNotEmpty && user.email.isNotEmpty) {
          _currentUser = user;
        }
      }
    } catch (_) {
      // Silently clear corrupt prefs; user will see LoginScreen
      await _clearPrefs();
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Authenticates the user. Returns `true` on success, `false` on failure.
  /// On failure, [errorMessage] is populated for the UI to display.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authService.login(email.trim(), password);
      _currentUser = user;
      await _persistSession(user);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Logs out the user locally and (optionally) revokes the server token.
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout(_currentUser?.token);
    } catch (_) {
      // Even if the server call fails, we clear the local session.
    } finally {
      _currentUser = null;
      await _clearPrefs();
      _setLoading(false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _persistSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    final flat = user.toPrefs();
    for (final entry in flat.entries) {
      await prefs.setString(entry.key, entry.value);
    }
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsLoggedIn);
    for (final key in [
      _kUserId, _kUserName, _kUserEmail, _kUserRole, _kUserToken
    ]) {
      await prefs.remove(key);
    }
  }
}
