// lib/services/database_init_desktop.dart
//
// Desktop implementation — Windows, Linux, macOS.
// Imported ONLY when compiled for native non-mobile targets.
// dart:io and dart:ffi are both available here.

import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android / iOS: sqflite native factory is auto-initialized.
}
