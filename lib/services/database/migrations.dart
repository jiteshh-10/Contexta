import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Database migrations handler
///
/// This class manages all schema changes across versions.
/// Each migration is isolated and can be tested independently.
///
/// To add a new migration:
/// 1. Increment _databaseVersion in database_service.dart
/// 2. Add a new case in the migrate() method
/// 3. Document the changes in the migration comment
class DatabaseMigrations {
  /// Execute migration from one version to the next
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint(
      'DatabaseMigrations: Running migration from v$oldVersion to v$newVersion',
    );

    switch (newVersion) {
      case 1:
        await _migrateV0ToV1(db);
        break;
      case 2:
        await _migrateV1ToV2(db);
        break;
      // Add future migrations here:
      // case 3:
      //   await _migrateV2ToV3(db);
      //   break;
      default:
        throw Exception('Unknown database version: $newVersion');
    }
  }

  /// Migration v0 -> v1: Initial schema
  ///
  /// Tables created:
  /// - books: Store book metadata
  /// - word_entries: Store captured words
  /// - word_explanation_cache: Cache API explanations for offline access
  /// - sync_queue: Track pending sync operations (for future sync feature)
  /// - app_metadata: Store app-level metadata and settings
  static Future<void> _migrateV0ToV1(Database db) async {
    debugPrint('DatabaseMigrations: Creating initial schema v1');

    // ========================================
    // Books table
    // ========================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS books (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        cover_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        
        -- Flexible metadata field for future extensions
        -- Store as JSON string
        metadata TEXT DEFAULT '{}'
      )
    ''');

    // Index for faster queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_books_created_at 
      ON books (created_at DESC)
    ''');

    // ========================================
    // Word entries table
    // ========================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS word_entries (
        id TEXT PRIMARY KEY NOT NULL,
        book_id TEXT NOT NULL,
        word TEXT NOT NULL,
        explanation TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        
        -- Track if explanation came from cache or API
        source TEXT DEFAULT 'api',
        
        -- Flexible metadata field for future extensions
        metadata TEXT DEFAULT '{}',
        
        -- Foreign key to books table
        FOREIGN KEY (book_id) REFERENCES books (id) 
          ON DELETE CASCADE 
          ON UPDATE CASCADE
      )
    ''');

    // Indexes for faster queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_word_entries_book_id 
      ON word_entries (book_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_word_entries_timestamp 
      ON word_entries (timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_word_entries_word 
      ON word_entries (word COLLATE NOCASE)
    ''');

    // ========================================
    // Word explanation cache table
    // Core table for offline-first functionality
    // ========================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS word_explanation_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        
        -- Cache key components
        word TEXT NOT NULL,
        book_title TEXT NOT NULL,
        book_author TEXT NOT NULL,
        
        -- Cached response
        explanation TEXT NOT NULL,
        
        -- Cache metadata
        created_at TEXT NOT NULL,
        expires_at TEXT,
        hit_count INTEGER DEFAULT 0,
        last_accessed_at TEXT NOT NULL,
        
        -- Flexible metadata for future extensions
        metadata TEXT DEFAULT '{}',
        
        -- Unique constraint on cache key
        UNIQUE(word, book_title, book_author)
      )
    ''');

    // Index for cache lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_lookup 
      ON word_explanation_cache (word, book_title, book_author)
    ''');

    // Index for cache cleanup
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_expires 
      ON word_explanation_cache (expires_at)
    ''');

    // Index for LRU eviction
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_lru 
      ON word_explanation_cache (last_accessed_at)
    ''');

    // ========================================
    // Sync queue table (for future online sync)
    // ========================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        
        -- Operation details
        operation TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        
        -- Sync status
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        error_message TEXT,
        
        -- Timestamps
        created_at TEXT NOT NULL,
        processed_at TEXT,
        
        -- Metadata
        metadata TEXT DEFAULT '{}'
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_status 
      ON sync_queue (status, created_at)
    ''');

    // ========================================
    // App metadata table
    // ========================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    debugPrint('DatabaseMigrations: v1 schema created successfully');
  }

  /// Migration v1 -> v2: Add reading streak tracking
  ///
  /// Tables created:
  /// - reading_days: Track unique days when words were saved
  static Future<void> _migrateV1ToV2(Database db) async {
    debugPrint('DatabaseMigrations: Migrating to v2 - Reading streak');

    // ========================================
    // Reading days table for streak tracking
    // ========================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        
        -- Date in yyyy-MM-dd format (local timezone)
        date TEXT NOT NULL UNIQUE,
        
        -- When this record was created
        created_at TEXT NOT NULL
      )
    ''');

    // Index for date lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_reading_days_date 
      ON reading_days (date DESC)
    ''');

    debugPrint('DatabaseMigrations: v2 migration complete');
  }

  // ========================================
  // Future migration templates
  // ========================================

  /// Example migration v1 -> v2
  /// Uncomment and modify when needed
  // static Future<void> _migrateV1ToV2(Database db) async {
  //   debugPrint('DatabaseMigrations: Migrating to v2');
  //
  //   // Example: Add a new column
  //   await db.execute('''
  //     ALTER TABLE books ADD COLUMN reading_progress REAL DEFAULT 0.0
  //   ''');
  //
  //   // Example: Create a new table
  //   await db.execute('''
  //     CREATE TABLE IF NOT EXISTS reading_sessions (
  //       id TEXT PRIMARY KEY NOT NULL,
  //       book_id TEXT NOT NULL,
  //       start_time TEXT NOT NULL,
  //       end_time TEXT,
  //       pages_read INTEGER DEFAULT 0,
  //       FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
  //     )
  //   ''');
  //
  //   debugPrint('DatabaseMigrations: v2 migration complete');
  // }
}
