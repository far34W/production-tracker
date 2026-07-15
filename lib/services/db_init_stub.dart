// lib/services/db_init_stub.dart
//
// Fallback stub. This file is NEVER compiled directly.
// The conditional import in database_service.dart selects either:
//   db_init_native.dart  (when dart.library.io  is available)
//   db_init_web.dart     (when dart.library.html is available)
//
// This stub exists only so the Dart analyzer can resolve the symbol
// `initForPlatform` when neither condition is satisfied (rare edge cases
// like some test environments).

Future<void> initForPlatform() async {
  // Stub — real implementations are in db_init_native.dart / db_init_web.dart
}
