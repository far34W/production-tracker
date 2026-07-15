// lib/services/db_init_web.dart
//
// Compiled on: Web (Chrome, Firefox, Safari via dart.library.html)
// NOT compiled on: Android · iOS · Desktop
//
// dart:io is NOT available here. dart:html IS available.
// databaseFactoryFfi is NOT usable here — it requires dart:ffi which
// does not exist in the browser runtime.
//
// Instead we use sqflite_common_ffi_web which ships a WASM-compiled
// SQLite3 binary (sqlite3.wasm) that executes entirely in the browser.

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // for databaseFactory symbol

/// Initializes the web SQLite factory.
///
/// databaseFactoryFfiWeb is provided by sqflite_common_ffi_web.
/// It bootstraps the sql.js / sqlite3.wasm worker in the browser.
///
/// Data is stored in IndexedDB (persisted across sessions) or in-memory
/// depending on the path passed to openDatabase():
///   inMemoryDatabasePath  → in-memory (lost on page refresh)
///   any other path        → backed by IndexedDB (persisted)
Future<void> initForPlatform() async {
  // Point the global factory at the WASM-backed web implementation.
  databaseFactory = databaseFactoryFfiWeb;
}
