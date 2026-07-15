// lib/services/database_init_stub.dart
//
// Fallback used on Android and iOS.
// sqflite self-initializes on these platforms — nothing to do.

Future<void> initDatabaseFactory() async {
  // No-op on Android / iOS.
}
