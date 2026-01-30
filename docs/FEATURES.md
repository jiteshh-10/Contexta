# Contexta - Feature Documentation

> **Version:** 1.1.0  
> **Last Updated:** January 30, 2026  
> **Authors:** Development Team

---

## Table of Contents

1. [Offline-First Word Explanations](#1-offline-first-word-explanations)
   - [Overview](#11-overview)
   - [Architecture](#12-architecture)
   - [Database Schema](#13-database-schema)
   - [Services](#14-services)
   - [Usage](#15-usage)
   - [Configuration](#16-configuration)
2. [Context-Aware Rephrasing Levels](#2-context-aware-rephrasing-levels)
   - [Overview](#21-overview)
   - [Explanation Levels](#22-explanation-levels)
   - [UI Components](#23-ui-components)
   - [Integration](#24-integration)
   - [Customization](#25-customization)
3. [API Reference](#3-api-reference)
4. [Troubleshooting](#4-troubleshooting)

---

## 1. Offline-First Word Explanations

### 1.1 Overview

The offline-first architecture ensures that users can access word explanations even without an internet connection. All API responses are cached locally in a SQLite database, providing instant access to previously looked-up words.

**Key Benefits:**
- ✅ Works fully offline for saved books/words
- ✅ Instant responses for cached explanations
- ✅ Reduced API costs through intelligent caching
- ✅ Improved user experience with faster load times

### 1.2 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Request                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PerplexityService                             │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────────┐  │
│  │ Check Cache │───▶│ Check Online │───▶│ Call Perplexity   │  │
│  │    First    │    │    Status    │    │       API         │  │
│  └─────────────┘    └──────────────┘    └───────────────────┘  │
│         │                   │                     │              │
│         │ HIT               │ OFFLINE             │ SUCCESS      │
│         ▼                   ▼                     ▼              │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────────┐  │
│  │   Return    │    │ Return Cache │    │  Cache Response   │  │
│  │   Cached    │    │  or Error    │    │  Then Return      │  │
│  └─────────────┘    └──────────────┘    └───────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SQLite Database                             │
│  ┌──────────┐  ┌─────────────┐  ┌─────────────────────────────┐ │
│  │  books   │  │ word_entries│  │ word_explanation_cache      │ │
│  └──────────┘  └─────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Database Schema

#### Tables

##### `books`
| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT PRIMARY KEY | Unique book identifier |
| `title` | TEXT NOT NULL | Book title |
| `author` | TEXT NOT NULL | Author name |
| `cover_url` | TEXT | Optional cover image URL |
| `created_at` | TEXT NOT NULL | ISO 8601 timestamp |
| `updated_at` | TEXT NOT NULL | ISO 8601 timestamp |
| `metadata` | TEXT DEFAULT '{}' | JSON for future extensions |

##### `word_entries`
| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT PRIMARY KEY | Unique word entry ID |
| `book_id` | TEXT NOT NULL | Foreign key to books |
| `word` | TEXT NOT NULL | The captured word |
| `explanation` | TEXT NOT NULL | API explanation |
| `timestamp` | TEXT NOT NULL | When word was added |
| `source` | TEXT DEFAULT 'api' | 'api' or 'cache' |
| `metadata` | TEXT DEFAULT '{}' | JSON for extensions |

##### `word_explanation_cache`
| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER PRIMARY KEY | Auto-increment ID |
| `word` | TEXT NOT NULL | Normalized word (lowercase) |
| `book_title` | TEXT NOT NULL | Book context |
| `book_author` | TEXT NOT NULL | Author context |
| `explanation` | TEXT NOT NULL | Cached explanation |
| `created_at` | TEXT NOT NULL | Cache timestamp |
| `expires_at` | TEXT | Expiration timestamp |
| `hit_count` | INTEGER DEFAULT 0 | Access counter |
| `last_accessed_at` | TEXT NOT NULL | LRU tracking |
| `metadata` | TEXT DEFAULT '{}' | JSON for extensions |

##### `sync_queue` (Future Use)
| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER PRIMARY KEY | Auto-increment ID |
| `operation` | TEXT NOT NULL | Operation type |
| `table_name` | TEXT NOT NULL | Target table |
| `record_id` | TEXT NOT NULL | Record identifier |
| `data` | TEXT NOT NULL | JSON payload |
| `status` | TEXT DEFAULT 'pending' | Sync status |
| `retry_count` | INTEGER DEFAULT 0 | Retry attempts |
| `created_at` | TEXT NOT NULL | Queue timestamp |

#### Indexes
```sql
-- Books
CREATE INDEX idx_books_created_at ON books (created_at DESC);

-- Word Entries
CREATE INDEX idx_word_entries_book_id ON word_entries (book_id);
CREATE INDEX idx_word_entries_timestamp ON word_entries (timestamp DESC);
CREATE INDEX idx_word_entries_word ON word_entries (word COLLATE NOCASE);

-- Cache
CREATE INDEX idx_cache_lookup ON word_explanation_cache (word, book_title, book_author);
CREATE INDEX idx_cache_expires ON word_explanation_cache (expires_at);
CREATE INDEX idx_cache_lru ON word_explanation_cache (last_accessed_at);
```

### 1.4 Services

#### DatabaseService
**Location:** `lib/services/database/database_service.dart`

Singleton service managing SQLite database operations.

```dart
// Get database instance
final db = await DatabaseService().database;

// Basic operations
await DatabaseService().insert('table_name', {'column': 'value'});
await DatabaseService().query('table_name', where: 'id = ?', whereArgs: ['123']);
await DatabaseService().update('table_name', {'column': 'new_value'}, where: 'id = ?');
await DatabaseService().delete('table_name', where: 'id = ?', whereArgs: ['123']);

// Transactions
await DatabaseService().transaction((txn) async {
  // Multiple operations in single transaction
});

// Maintenance
await DatabaseService().vacuum(); // Reclaim space
await DatabaseService().clearAllData(); // Reset database
```

#### WordExplanationCacheService
**Location:** `lib/services/word_explanation_cache_service.dart`

Manages word explanation caching with LRU eviction.

```dart
final cache = WordExplanationCacheService();

// Check cache
final result = await cache.getExplanation(
  word: 'ephemeral',
  bookTitle: '1984',
  bookAuthor: 'George Orwell',
);

if (result.hit) {
  print(result.explanation); // Cached explanation
}

// Store in cache
await cache.cacheExplanation(
  word: 'ephemeral',
  bookTitle: '1984',
  bookAuthor: 'George Orwell',
  explanation: 'Lasting only a brief moment...',
);

// Cache management
await cache.clearExpired(); // Remove expired entries
await cache.clearForBook('1984', 'George Orwell'); // Clear book-specific cache
await cache.clearAll(); // Clear entire cache

// Statistics
final stats = await cache.getStats();
// {totalEntries: 150, totalHits: 1200, oldestEntry: '2026-01-01', ...}
```

#### ConnectivityService
**Location:** `lib/services/connectivity_service.dart`

Real-time network status monitoring.

```dart
final connectivity = ConnectivityService();

// Initialize (call once at app start)
await connectivity.initialize();

// Check status
if (connectivity.isOnline) {
  // Make API call
} else {
  // Use cached data
}

// Listen to changes
connectivity.statusStream.listen((status) {
  switch (status) {
    case ConnectivityStatus.online:
      // Sync pending operations
      break;
    case ConnectivityStatus.offline:
      // Switch to offline mode
      break;
  }
});
```

### 1.5 Usage

#### Basic Word Explanation Flow

```dart
final perplexityService = PerplexityService();

// Get explanation (automatically checks cache first)
final result = await perplexityService.explainWord(
  word: 'ephemeral',
  bookTitle: '1984',
  bookAuthor: 'George Orwell',
);

if (result.success) {
  print(result.explanation);
  print(result.isFromCache ? 'From cache' : 'From API');
}
```

#### Force Fresh API Call

```dart
final result = await perplexityService.explainWord(
  word: 'ephemeral',
  bookTitle: '1984',
  bookAuthor: 'George Orwell',
  forceRefresh: true, // Skip cache, fetch fresh
);
```

### 1.6 Configuration

#### Cache Settings
Located in `WordExplanationCacheService`:

```dart
static const int maxCacheSize = 10000;        // Max entries before LRU eviction
static const Duration defaultCacheDuration = Duration(days: 365); // 1 year expiry
```

#### Database Version
Located in `DatabaseService`:

```dart
static const int _databaseVersion = 1; // Increment for schema changes
```

---

## 2. Context-Aware Rephrasing Levels

### 2.1 Overview

The rephrasing levels feature allows users to customize the depth of word explanations based on their reading goals. Three levels are available, each with tailored AI prompts.

**Key Benefits:**
- ✅ Personalized reading experience
- ✅ Quick lookups for casual reading (Simple)
- ✅ Rich context for literary analysis (Deep)
- ✅ Persistent user preference

### 2.2 Explanation Levels

#### Simple (◯)
**Use Case:** Quick reference, casual reading

| Aspect | Details |
|--------|---------|
| Definition Length | 3-4 words |
| Context | One example sentence |
| Max Tokens | 150 |
| Tone | Everyday language |

**Example Output:**
```
Very old or ancient
---
The museum displayed antediluvian fossils from millions of years ago.
```

#### Literary (◐)
**Use Case:** Book club discussions, deeper understanding

| Aspect | Details |
|--------|---------|
| Definition Length | 4-5 words |
| Context | 2-3 sentences with literary significance |
| Max Tokens | 300 |
| Tone | Sophisticated but accessible |

**Example Output:**
```
Lasting only a brief moment
---
In the context of this novel, "ephemeral" captures the fleeting nature of 
human connections and memories that the author weaves throughout the narrative. 
It emphasizes how precious moments become precisely because they cannot last forever.
```

#### Deep (●)
**Use Case:** Academic study, language enthusiasts

| Aspect | Details |
|--------|---------|
| Definition Length | 4-5 words |
| Content | Etymology + Literary Context + Usage Note |
| Max Tokens | 500 |
| Tone | Scholarly yet accessible |

**Example Output:**
```
Lasting only a brief moment
---
From Greek "ephemeros" meaning "lasting only a day," derived from "epi" (on) 
+ "hemera" (day). The word entered English in the 16th century, initially 
describing fever that lasted a single day.
---
In Fitzgerald's prose, "ephemeral" becomes a meditation on the American Dream's 
fundamental fragility. The word choice deliberately echoes the Romantic poets' 
obsession with transience, particularly Keats's "Ode on a Grecian Urn."
---
Often confused with "ethereal"; ephemeral emphasizes brevity of duration 
rather than delicacy of substance.
```

### 2.3 UI Components

#### ExplanationLevelSelector
**Location:** `lib/widgets/explanation_level_selector.dart`

A beautiful animated segmented control.

```dart
ExplanationLevelSelector(
  selectedLevel: _currentLevel,
  onLevelChanged: (level) {
    setState(() => _currentLevel = level);
    _storageService.saveExplanationLevel(level);
  },
  enabled: !_isLoading, // Disable during API calls
)
```

**Features:**
- Smooth sliding indicator animation (250ms, easeOutCubic)
- Haptic feedback on selection
- Visual icons (◯, ◐, ●) for quick recognition
- Dark/Light theme support
- Disabled state during loading

#### ExplanationLevelSelectorCompact
A smaller variant for space-constrained layouts.

```dart
ExplanationLevelSelectorCompact(
  selectedLevel: _currentLevel,
  onLevelChanged: _handleLevelChange,
)
```

### 2.4 Integration

#### In BookDetailScreen

```dart
class _BookDetailScreenState extends State<BookDetailScreen> {
  ExplanationLevel _explanationLevel = ExplanationLevel.simple;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadExplanationLevel();
  }

  void _loadExplanationLevel() {
    final saved = _storageService.loadExplanationLevel();
    setState(() => _explanationLevel = saved);
  }

  void _setExplanationLevel(ExplanationLevel level) {
    setState(() => _explanationLevel = level);
    _storageService.saveExplanationLevel(level);
  }

  Future<void> _explainWord() async {
    final result = await _perplexityService.explainWord(
      word: _word,
      bookTitle: widget.book.title,
      bookAuthor: widget.book.author,
      level: _explanationLevel, // Pass selected level
    );
    // Handle result...
  }
}
```

#### Cache Key Generation

Each level creates a unique cache key to allow switching between levels:

```dart
// Cache key format: "{word}_{level}"
final cacheKey = '${word.toLowerCase()}_${level.name}';

// Examples:
// "ephemeral_simple"
// "ephemeral_literary"
// "ephemeral_deep"
```

### 2.5 Customization

#### Adding a New Level

1. Add to `ExplanationLevel` enum:

```dart
enum ExplanationLevel {
  simple(...),
  literary(...),
  deep(...),
  academic(  // New level
    label: 'Academic',
    description: 'Scholarly depth',
    icon: '◆',
  );
}
```

2. Add system prompt:

```dart
String get systemPrompt {
  switch (this) {
    // ... existing cases
    case ExplanationLevel.academic:
      return '''Your scholarly prompt here...''';
  }
}
```

3. Add max tokens:

```dart
int get maxTokens {
  switch (this) {
    // ... existing cases
    case ExplanationLevel.academic:
      return 600;
  }
}
```

#### Customizing UI

Modify `ExplanationLevelSelector`:

```dart
// Animation duration
duration: const Duration(milliseconds: 250),

// Animation curve
curve: Curves.easeOutCubic,

// Indicator styling
decoration: BoxDecoration(
  color: indicatorColor,
  borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 4),
  boxShadow: [...],
),
```

---

## 3. API Reference

### PerplexityService

```dart
/// Explain a word with context and caching
Future<WordExplanationResult> explainWord({
  required String word,
  required String bookTitle,
  required String bookAuthor,
  ExplanationLevel level = ExplanationLevel.simple,
  bool forceRefresh = false,
})
```

### WordExplanationResult

```dart
class WordExplanationResult {
  final bool success;           // Operation succeeded
  final String? explanation;    // The explanation text
  final String? error;          // Error message if failed
  final String source;          // 'cache', 'api', or 'error'
  
  bool get isFromCache;         // Quick check for cache hit
}
```

### ExplanationLevel

```dart
enum ExplanationLevel {
  simple,    // Brief definitions
  literary,  // Contextual depth
  deep;      // Full analysis

  String get label;              // Display name
  String get description;        // Short description
  String get icon;               // Visual indicator
  String get systemPrompt;       // AI prompt
  int get maxTokens;             // API token limit
  
  String toStorageString();
  static ExplanationLevel fromStorageString(String?);
}
```

### StorageService

```dart
// Explanation Level
Future<bool> saveExplanationLevel(ExplanationLevel level);
ExplanationLevel loadExplanationLevel();
```

---

## 4. Troubleshooting

### Common Issues

#### Cache Not Working
**Symptoms:** Always shows "From API", never "From cache"

**Solutions:**
1. Verify database initialized: Check logs for `DatabaseService: Initialized`
2. Check cache key: Ensure word/title/author match exactly
3. Clear and retry: `await WordExplanationCacheService().clearAll()`

#### Offline Mode Not Activating
**Symptoms:** App crashes or hangs when offline

**Solutions:**
1. Verify connectivity initialized: Check logs for `ConnectivityService: Initialized`
2. Test status: `print(ConnectivityService().status)`
3. Check permissions in `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
   ```

#### Database Migration Errors
**Symptoms:** App crashes on startup after update

**Solutions:**
1. Check version number in `DatabaseService._databaseVersion`
2. Ensure migration exists in `DatabaseMigrations.migrate()`
3. For development: Clear app data to reset database

#### Level Not Persisting
**Symptoms:** Level resets to Simple on app restart

**Solutions:**
1. Verify StorageService initialized before use
2. Check SharedPreferences access:
   ```dart
   print(StorageService().loadExplanationLevel());
   ```

### Debug Logging

Enable verbose logging by checking Flutter console for:
```
DatabaseService: Initializing database at /path/to/contexta.db
DatabaseMigrations: Running migration from v0 to v1
WordExplanationCache: HIT for "word"
WordExplanationCache: MISS for "word"
WordExplanationCache: Cached "word"
ConnectivityService: Status changed to ConnectivityStatus.online
```

---

## Appendix

### File Structure

```
lib/
├── models/
│   ├── book.dart
│   ├── word_entry.dart
│   └── explanation_level.dart       # NEW
├── services/
│   ├── database/
│   │   ├── database.dart             # NEW
│   │   ├── database_service.dart     # NEW
│   │   └── migrations.dart           # NEW
│   ├── connectivity_service.dart     # NEW
│   ├── perplexity_service.dart       # MODIFIED
│   ├── storage_service.dart          # MODIFIED
│   └── word_explanation_cache_service.dart  # NEW
├── widgets/
│   └── explanation_level_selector.dart      # NEW
└── screens/
    └── book_detail_screen.dart       # MODIFIED
```

### Dependencies Added

```yaml
# pubspec.yaml
dependencies:
  sqflite: ^2.4.2           # SQLite database
  path: ^1.9.1              # Path utilities
  connectivity_plus: ^6.1.4  # Network status
```

---

*This documentation is part of the Contexta project. For questions or contributions, please refer to the project repository.*
