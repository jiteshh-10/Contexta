import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'migrations.dart';

/// Industry-grade database service with migration support
///
/// Features:
/// - Versioned migrations for schema evolution
/// - Singleton pattern for consistent access
/// - Error handling and recovery
/// - Foreign key support
/// - Indexed queries for performance
class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const String _databaseName = 'contexta.db';

  // Current database version - increment when schema changes
  static const int _databaseVersion = 3;

  /// Get database instance, initializing if needed
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Check if database is initialized
  bool get isInitialized => _database != null;

  /// Initialize the database
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      debugPrint('DatabaseService: Initializing database at $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: onDatabaseDowngradeDelete,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      debugPrint('DatabaseService: Error initializing database: $e');
      rethrow;
    }
  }

  /// Configure database settings
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys for referential integrity
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create tables on first install
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('DatabaseService: Creating database v$version');

    // Run all migrations from version 0 to current
    for (int i = 1; i <= version; i++) {
      await DatabaseMigrations.migrate(db, i - 1, i);
    }
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint(
      'DatabaseService: Upgrading database from v$oldVersion to v$newVersion',
    );

    // Run incremental migrations
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      await DatabaseMigrations.migrate(db, i - 1, i);
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('DatabaseService: Database closed');
    }
  }

  /// Execute a raw SQL query (for complex queries)
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  /// Execute a raw SQL command (for inserts, updates, deletes)
  Future<int> rawExecute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return db.rawInsert(sql, arguments);
  }

  /// Insert data into a table
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update data in a table
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// Delete data from a table
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Query data from a table
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Run a batch of operations in a transaction
  Future<List<Object?>> batch(void Function(Batch batch) operations) async {
    final db = await database;
    final batch = db.batch();
    operations(batch);
    return batch.commit();
  }

  /// Run operations in a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  /// Get database file size (for debugging/stats)
  Future<int> getDatabaseSize() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()',
      );
      return result.first['size'] as int? ?? 0;
    } catch (e) {
      debugPrint('DatabaseService: Error getting database size: $e');
      return 0;
    }
  }

  /// Vacuum database to reclaim space
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
    debugPrint('DatabaseService: Database vacuumed');
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      // Get all table names
      final tables = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
      );

      // Delete from each table
      for (final table in tables) {
        final tableName = table['name'] as String;
        await txn.delete(tableName);
      }
    });
    debugPrint('DatabaseService: All data cleared');
  }
}
