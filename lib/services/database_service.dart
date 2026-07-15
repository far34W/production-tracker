// lib/services/database_service.dart
//
// ═══════════════════════════════════════════════════════════════════════════
// PLATFORM SUPPORT
// ═══════════════════════════════════════════════════════════════════════════
//   Android   → sqflite native (auto)     no-op stub
//   iOS       → sqflite native (auto)     no-op stub
//   Windows   → sqfliteFfiInit + ffi      desktop impl
//   Linux     → sqfliteFfiInit + ffi      desktop impl
//   macOS     → sqfliteFfiInit + ffi      desktop impl
//   Web       → databaseFactoryFfiWeb     web WASM impl
// ═══════════════════════════════════════════════════════════════════════════
//
// IMPORTANT — Web requires the WASM setup step to have been run:
//
//   dart run sqflite_common_ffi_web:setup
//
// This copies web/sqlite3.wasm + web/sqflite_sw.js into your project.
// Without these two files, openDatabase() on web throws:
//   "Unsupported result null (null)"
// (See database_init_web.dart for full explanation.)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/production_entry.dart';

// ── Conditional import — compile-time platform selection ──────────────────
//   Web    (dart.library.html present) → database_init_web.dart
//   Native (dart.library.html absent)  → database_init_desktop.dart
import 'database_init_desktop.dart'
    if (dart.library.html) 'database_init_web.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static Database? _db;

  static const _dbName    = 'production_tracker.db';
  static const _dbVersion = 2;
  static const _table     = 'production_entries';
  Future<Database> get database async {
_db ??= await _init();
return _db!;
}
Future<Database> _init() async {
  print('STEP 1');
  await initDatabaseFactory();

  print('STEP 2');

if (kIsWeb) {
  print('OPENING WEB DB');
  print('FACTORY = ${databaseFactory.runtimeType}');

  return openDatabase(
    _dbName,
    version: _dbVersion,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
  );
}

  final dbPath = await getDatabasesPath();
  final path = join(dbPath, _dbName);

return await databaseFactory.openDatabase(
  _dbName,
  options: OpenDatabaseOptions(
    version: _dbVersion,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  ),
);
}

// ── Schema v2 ──────────────────────────────────────────────────────────

// ── Schema v2 ──────────────────────────────────────────────────────────
  // ── Schema v2 ──────────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        date          TEXT    NOT NULL,
        operator_name TEXT    NOT NULL,
        shift         TEXT    NOT NULL,
        cad_debut     REAL,
        cad_fin       REAL,
        ct2_debut     REAL,
        ct2_fin       REAL,
        ct2p_debut    REAL,
        ct2p_fin      REAL,
        sl3_debut     REAL,
        sl3_fin       REAL,
        energy_debut  REAL,
        energy_fin    REAL,
        amine         REAL,
        acide         REAL,
        ester         REAL,
        floculant     REAL,
        running_hours REAL,
        notes         TEXT,
        created_at    TEXT    NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_date ON $_table(date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final col in [
        'ct2p_debut', 'ct2p_fin',
        'amine', 'acide', 'ester', 'floculant',
        'running_hours',
      ]) {
        try {
          await db.execute('ALTER TABLE $_table ADD COLUMN $col REAL');
        } catch (_) {
          // Column already exists — safe to continue.
        }
      }
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

 Future<int> insert(ProductionEntry entry) async {
  try {
    print('INSERT START');

    final db = await database;

    print('DB OPENED');

    return await db.insert(
      _table,
      entry.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e, s) {
    print('INSERT ERROR: $e');
    print(s);
    rethrow;
  }
}

  Future<List<ProductionEntry>> getAll({String? orderBy}) async {
    final db   = await database;
    final rows = await db.query(
      _table,
      orderBy: orderBy ?? 'date DESC, shift ASC',
    );
    return rows.map(ProductionEntry.fromMap).toList();
  }

  Future<ProductionEntry?> getLatestEntry() async {
    final db   = await database;
    final rows = await db.query(
      _table,
      orderBy: 'date DESC, created_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : ProductionEntry.fromMap(rows.first);
  }

  Future<List<ProductionEntry>> getByMonth(int year, int month) async {
    final db     = await database;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final rows   = await db.query(
      _table,
      where:     'date LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy:   'date ASC, shift ASC',
    );
    return rows.map(ProductionEntry.fromMap).toList();
  }

  Future<int> update(ProductionEntry entry) async {
    final db = await database;
    return db.update(
      _table,
      entry.toMap(),
      where:     'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> dropAndRecreate() async {
    assert(kDebugMode, 'dropAndRecreate is for debug use only');
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS $_table');
    await _onCreate(db, _dbVersion);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
