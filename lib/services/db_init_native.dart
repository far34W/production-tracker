// lib/services/db_init_native.dart
//
// Compiled on: Android · iOS · Windows · Linux · macOS
// NOT compiled on: Web (dart.library.html)
//
// dart:io IS available here, so Platform.isWindows etc. are safe to call.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes the correct sqflite factory for the current native platform.
///
/// Desktop (Windows / Linux / macOS):
///   sqfliteFfiInit() loads the native SQLite shared library via dart:ffi.
///   databaseFactory is then pointed at databaseFactoryFfi.
///
/// Mobile (Android / iOS):
///   sqflite self-initializes — no action needed.
///   Calling sqfliteFfiInit() on mobile would throw, so we guard with
///   the Platform checks.
Future<void> initForPlatform() async {
  // kIsWeb is always false here (this file is not compiled for web),
  // but the guard is kept for clarity and safety.
  if (kIsWeb) return;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // sqfliteFfiInit() discovers and loads the native sqlite3 shared library.
    // Must be called EXACTLY ONCE before any openDatabase() call.
    sqfliteFfiInit();

    // Override the global factory so openDatabase() uses the FFI backend.
    databaseFactory = databaseFactoryFfi;
  }

  // Platform.isAndroid / Platform.isIOS → no-op, sqflite handles itself.
}
