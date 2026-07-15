// lib/widgets/splash_screen.dart
//
// Shown for the ~300 ms while SharedPreferences is being read.
// Uses the same gradient as LoginScreen for a seamless feel.

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF002171),
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF1976D2),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo mark
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.factory_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
