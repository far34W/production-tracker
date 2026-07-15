// lib/widgets/logout_button.dart
//
// A ready-made logout button you can drop into your AppBar actions
// or drawer footer.
//
// Usage in AppBar:
//   actions: const [LogoutButton()],
//
// Usage in Drawer:
//   ListTile(
//     leading: const Icon(Icons.logout),
//     title: const Text('Logout'),
//     onTap: () => const LogoutButton()._handleLogout(context),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) => IconButton(
        tooltip: 'Sign out',
        icon: auth.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.logout_rounded),
        onPressed: auth.isLoading ? null : () => _handleLogout(context),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out'),
        content: const Text(
          'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      // AuthGate will automatically switch to LoginScreen — no push needed.
    }
  }
}
