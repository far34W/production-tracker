// lib/main.dart  ← REPLACE YOUR EXISTING main.dart WITH THIS
//
// Changes from original:
//   1. Added SharedPreferences dependency resolution
//   2. Wrapped MultiProvider to include AuthProvider
//   3. AuthProvider.tryRestoreSession() called before runApp
//   4. MaterialApp home → AuthGate (replaces direct _AppShell)
//   5. LogoutButton added to the Entries tab AppBar actions
//
// Everything else (ProductionProvider, screens, theme) is untouched.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Existing providers — keep as-is
import 'providers/production_provider.dart';

// ── NEW: auth providers & widgets ─────────────────────────────────────────────
import 'providers/auth_provider.dart';
import 'widgets/auth_gate.dart';
import 'widgets/logout_button.dart';
// ─────────────────────────────────────────────────────────────────────────────

import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/entries_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── NEW: restore session before showing any UI ────────────────────────────
  final authProvider = AuthProvider();
  await authProvider.tryRestoreSession();
  // ──────────────────────────────────────────────────────────────────────────

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        // ── NEW ──────────────────────────────────────────────────────────────
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        // ─────────────────────────────────────────────────────────────────────
        // Existing provider — unchanged
        ChangeNotifierProvider(
          create: (_) => ProductionProvider()..initialize(),
        ),
      ],
      child: const ProductionApp(),
    ),
  );
}

class ProductionApp extends StatelessWidget {
  const ProductionApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Production Tracker',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    // ── CHANGED: was `home: const _AppShell()` ──────────────────────────────
    // AuthGate now decides whether to show LoginScreen or AppShell.
    home: const AuthGate(),
    // ─────────────────────────────────────────────────────────────────────────
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppShell — your existing bottom-nav shell, UNCHANGED except:
//   • LogoutButton added to the Entries tab AppBar actions
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    EntriesScreen(),
  ];

  static const _labels = ['Dashboard', 'Entries'];

  static const _icons = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded),
    (Icons.assignment_outlined, Icons.assignment_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar only for the Entries tab (Dashboard has its own SliverAppBar)
      appBar: _index == 1
          ? AppBar(
              title: const Text('Production Entries'),
              actions: [
                // Quick export (unchanged)
                Consumer<ProductionProvider>(
                  builder: (_, provider, __) =>
                      _QuickExport(provider: provider),
                ),
                // ── NEW: logout button ─────────────────────────────────────
                const LogoutButton(),
                // ──────────────────────────────────────────────────────────
              ],
            )
          : null,

      body: IndexedStack(index: _index, children: _screens),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF0D47A1).withOpacity(0.12),
        destinations: List.generate(
          _screens.length,
          (i) => NavigationDestination(
            icon: Icon(_icons[i].$1),
            selectedIcon: Icon(_icons[i].$2),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}

// ── Quick export button (unchanged from original) ─────────────────────────────

class _QuickExport extends StatefulWidget {
  final ProductionProvider provider;
  const _QuickExport({required this.provider});

  @override
  State<_QuickExport> createState() => _QuickExportState();
}

class _QuickExportState extends State<_QuickExport> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Export visible entries to Excel',
      icon: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.upload_file_rounded),
      onPressed: _busy || widget.provider.entries.isEmpty ? null : _run,
    );
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.provider.exportFilteredToExcel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Excel file ready to share'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
