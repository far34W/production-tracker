// lib/widgets/auth_gate.dart
//
// The single widget that decides what the user sees:
//
//   isCheckingSession = true  →  SplashScreen (brief)
//   isAuthenticated   = true  →  DashboardShell (your existing app)
//   isAuthenticated   = false →  LoginScreen
//
// This replaces a manual Navigator.push approach and means you NEVER
// need to push/pop between login and dashboard — the Provider rebuild
// triggers automatically when isAuthenticated changes.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'splash_screen.dart';

/// Swap [DashboardShell] for whatever your top-level app widget is called.
/// If it's named `MainShell` or `_AppShell`, just update the import below.
// ignore: uri_does_not_exist
import '../main.dart' show AppShell; // ← change 'AppShell' to your class name

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // 1. Still reading SharedPreferences — show splash
        if (auth.isCheckingSession) {
          return const SplashScreen();
        }

        // 2. Session restored or just logged in
        if (auth.isAuthenticated) {
          return const AppShell(); // ← your existing dashboard widget
        }

        // 3. Not authenticated
        return const LoginScreen();
      },
    );
  }
}
