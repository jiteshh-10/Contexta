# Contexta - Complete Feature Documentation

> **Version:** 1.2.0  
> **Last Updated:** January 30, 2026  
> **Authors:** Development Team  
> **Repository:** github.com/jiteshh-10/Contexta

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Core Features (v1.0.0)](#2-core-features-v100)
   - [Personal Library System](#21-personal-library-system)
   - [Contextual Word Explanations](#22-contextual-word-explanations)
   - [Word Collection Management](#23-word-collection-management)
   - [Theme System](#24-theme-system)
   - [Design System & UI Components](#25-design-system--ui-components)
3. [Offline-First Word Explanations (v1.1.0)](#3-offline-first-word-explanations-v110)
   - [Overview](#31-overview)
   - [Architecture](#32-architecture)
   - [Database Schema](#33-database-schema)
   - [Services](#34-services)
   - [Usage](#35-usage)
   - [Configuration](#36-configuration)
4. [Context-Aware Rephrasing Levels (v1.1.0)](#4-context-aware-rephrasing-levels-v110)
   - [Overview](#41-overview)
   - [Explanation Levels](#42-explanation-levels)
   - [UI Components](#43-ui-components)
   - [Integration](#44-integration)
   - [Customization](#45-customization)
5. [Word Frequency Per Book (v1.2.0)](#5-word-frequency-per-book-v120)
   - [Overview](#51-overview)
   - [How It Works](#52-how-it-works)
   - [UI Components](#53-ui-components)
   - [Display Logic](#54-display-logic)
   - [Data Model](#55-data-model)
6. [API Reference](#6-api-reference)
7. [Project Architecture](#7-project-architecture)
8. [Troubleshooting](#8-troubleshooting)
9. [Changelog](#9-changelog)

---

## 1. Project Overview

### What is Contexta?

**Contexta** is a minimalist reading companion app for curious minds. Unlike traditional dictionary apps, Contexta provides **contextual explanations** — understanding words within the literary context of the book you're reading.

### The Problem

When reading challenging literature, encountering an unfamiliar word breaks the reading flow. Traditional dictionaries provide generic definitions that often miss the nuanced meaning the author intended.

### The Solution

Contexta leverages AI (Perplexity API) to explain words in the context of your current book, providing:
- A **short definition** (4-5 words)
- A **contextual explanation** considering the book's themes, genre, and author's style

### Example Comparison

| Traditional Dictionary | Contexta |
|----------------------|----------|
| "Love: A strong feeling of affection" | "In *The Brothers Karamazov*, 'love' transcends romantic notions—it embodies Father Zosima's Christian imperative of **active love**, a deliberate effort to embrace neighbors amid suffering." |

### Design Philosophy

Contexta follows a **"quiet luxury"** aesthetic — elegant, understated, and focused on content. The interface feels like a well-crafted journal, not a tech product.

---

## 2. Core Features (v1.0.0)

*Commit: `cdaf3e8` - Initial commit: Contexta reading companion app*

### 2.1 Personal Library System

The library is the heart of Contexta, organizing your reading journey.

#### Features
- Add books with title and author
- Visual book cards with stacked paper effect
- Persistent storage across app sessions
- Empty state with branded illustration
- Book deletion with slide-out animation

#### Book Model

**Location:** `lib/models/book.dart`

```dart
class Book {
  final String id;           // Unique identifier (timestamp-based)
  final String title;        // Book title
  final String author;       // Author name
  final String? coverUrl;    // Optional cover URL (future use)
  final DateTime createdAt;  // Creation timestamp
  final List<WordEntry> words; // Associated word entries
  
  // Helper methods
  Book addWord(WordEntry word);
  Book removeWord(String wordId);
  Book updateWord(WordEntry updatedWord);
  int get wordCount;
  bool get hasWords;
  
  // Serialization
  Map<String, dynamic> toJson();
  factory Book.fromJson(Map<String, dynamic> json);
}
```

#### Library Screen

**Location:** `lib/screens/library_screen.dart`

| Component | Description |
|-----------|-------------|
| App Bar | Title "Library" + theme toggle button |
| Book Grid | 2-column grid of BookCards |
| Empty State | Illustration + "Add a Book" CTA |
| FAB | Floating "+" button to add books |

#### Add Book Screen

**Location:** `lib/screens/add_book_screen.dart`

| Field | Validation |
|-------|------------|
| Title | Required, max 100 characters |
| Author | Required, defaults to "Unknown Author" |

```dart
// Creating a new book
final book = Book(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'The Brothers Karamazov',
  author: 'Fyodor Dostoevsky',
);
```

### 2.2 Contextual Word Explanations

The core feature that differentiates Contexta from traditional dictionaries.

#### Perplexity API Integration

**Location:** `lib/services/perplexity_service.dart`

```dart
class PerplexityService {
  /// Explain a word with book context
  Future<WordExplanationResult> explainWord({
    required String word,
    required String bookTitle,
    required String bookAuthor,
  });
}
```

#### API Configuration

**Location:** `lib/config/api_config.dart`

| Setting | Value | Description |
|---------|-------|-------------|
| Model | `sonar` | Perplexity's fast model |
| Max Tokens | 300 | Response length limit |
| Temperature | 0.3 | Focused, less creative |
| Timeout | 30 seconds | Request timeout |

#### System Prompt

The AI is instructed to respond in a specific format:

```
[4-5 word short definition in plain text]
---
[Detailed contextual explanation in 2-3 sentences explaining 
the word's significance in the context of the book or literary 
genre, using sophisticated but accessible language.]
```

#### Environment Setup

Create `.env` file in project root:

```env
PERPLEXITY_API_KEY=your_api_key_here
```

Get your API key from: https://www.perplexity.ai/settings/api

### 2.3 Word Collection Management

Each book maintains its own vocabulary collection.

#### Word Entry Model

**Location:** `lib/models/word_entry.dart`

```dart
class WordEntry {
  final String id;           // Unique identifier
  final String word;         // The captured word
  final String explanation;  // AI-generated explanation
  final String bookId;       // Parent book reference
  final DateTime timestamp;  // When word was added
  
  // Helper methods
  String get relativeTime;      // "2h ago", "3d ago"
  String get formattedDate;     // "30/01/2026"
  String get capitalizedWord;   // First letter uppercase
  
  // Serialization
  Map<String, dynamic> toJson();
  factory WordEntry.fromJson(Map<String, dynamic> json);
}
```

#### Word Collection Features

| Feature | Description |
|---------|-------------|
| Add Word | Enter word, tap "Explain", automatically saved |
| View Details | Tap word to see full explanation in bottom sheet |
| Edit Word | Modify word text and refetch explanation |
| Remove Word | Delete with haptic feedback confirmation |
| Sort Options | Recent, Oldest, A-Z, Z-A |

#### Sorting Implementation

```dart
enum SortOption {
  recent('Recently Added'),
  oldest('Oldest First'),
  alphabetical('A–Z'),
  reverseAlphabetical('Z–A');
}
```

### 2.4 Theme System

Carefully crafted light and dark themes for comfortable reading.

#### Color Palette

##### Light Mode
| Token | Hex | Usage |
|-------|-----|-------|
| `beige` | `#F5F1E8` | Warm background |
| `paper` | `#FFFFFF` | Cards, sheets |
| `inkBlue` | `#1A4B7C` | Primary accent |
| `charcoal` | `#2D2D2D` | Primary text |
| `textSecondary` | `#6B6B6B` | Secondary text |
| `textMuted` | `#9B9B9B` | Muted text |
| `border` | `#D4CFC0` | Dividers |
| `error` | `#B54B4B` | Error states |
| `success` | `#4B8B5E` | Success states |

##### Dark Mode
| Token | Hex | Usage |
|-------|-----|-------|
| `darkBackground` | `#1E1B18` | Deep brown-black |
| `darkPaper` | `#2A2520` | Dark parchment |
| `darkPaperElevated` | `#332E28` | Elevated surfaces |
| `darkTextPrimary` | `#EDE6D8` | Warm off-white text |
| `darkTextSecondary` | `#B5AD9E` | Muted taupe |
| `darkInkBlue` | `#7B8AB5` | Accent (brighter) |
| `darkBorder` | `#3D3832` | Dividers |

#### Theme Toggle

```dart
// In main.dart
void _toggleTheme() {
  setState(() {
    _themeMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
  });
  _storage.saveThemeMode(_themeMode == ThemeMode.dark ? 'dark' : 'light');
}
```

### 2.5 Design System & UI Components

#### Typography

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| Display | Georgia (Serif) | 28px | 500 | Screen titles |
| Headline | Georgia (Serif) | 24px | 500 | Section headers |
| Title | Georgia (Serif) | 20px | 500 | Card titles |
| Body | Inter | 16px | 400 | Main content |
| Caption | Inter | 14px | 400 | Secondary info |
| Button | Inter | 15px | 500 | Button labels |

#### Border Radius Scale

| Token | Value | Usage |
|-------|-------|-------|
| `radiusSmall` | 8px | Buttons, inputs |
| `radiusMedium` | 16px | Cards |
| `radiusLarge` | 20px | Larger cards |
| `radiusXLarge` | 24px | Pills, FAB |
| `radiusSheet` | 28px | Bottom sheets |

#### Animation System

| Animation | Duration | Curve | Usage |
|-----------|----------|-------|-------|
| Fade In | 700ms | easeOut | Screen transitions |
| Button Press | 120ms | easeOut | Tap feedback |
| Card Press | 200ms | easeOut | Card interactions |
| Sheet Enter | 200ms | easeOut | Bottom sheets |
| Dialog | 200ms | easeOut | Dialogs |
| Theme Transition | 300ms | easeOut | Theme changes |

#### Scale Values

| Token | Value | Usage |
|-------|-------|-------|
| `buttonPressedScale` | 0.97 | Button press effect |
| `cardPressedScale` | 0.98 | Card press effect |
| `cardHoverScale` | 1.01 | Card hover (desktop) |
| `fabPressedScale` | 0.95 | FAB press effect |

#### Widget Library

| Widget | Location | Description |
|--------|----------|-------------|
| `BookCard` | `widgets/book_card.dart` | Stacked paper effect card with animations |
| `ContextaAppBar` | `widgets/contexta_app_bar.dart` | Custom app bar with back button |
| `ContextaBottomSheet` | `widgets/contexta_bottom_sheet.dart` | Styled modal bottom sheet |
| `ContextaDialog` | `widgets/contexta_dialog.dart` | Confirmation dialogs |
| `ContextaTextField` | `widgets/contexta_text_field.dart` | Styled text input |
| `LoadingDots` | `widgets/loading_dots.dart` | Animated loading indicator |
| `Logo` | `widgets/logo.dart` | Brand logo with CustomPaint |
| `PrimaryButton` | `widgets/primary_button.dart` | Primary CTA button |
| `SecondaryButton` | `widgets/secondary_button.dart` | Secondary action button |
| `WordExplanationSheet` | `widgets/word_explanation_sheet.dart` | Word detail modal |
| `WordListItem` | `widgets/word_list_item.dart` | Word collection list item |

#### Logo Design

The Contexta logo combines three elements built with `CustomPaint`:

1. **Page corner fold** (top-right) - Represents reading
2. **C-shaped bracket** - Annotation/marginalia symbol
3. **Margin line** (left) - Scholarly annotation style

```dart
class ContextaLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool animated; // Fade-in animation on splash
}
```

#### Storage Service

**Location:** `lib/services/storage_service.dart`

Handles all local persistence using SharedPreferences.

```dart
class StorageService {
  // Books
  Future<bool> saveBooks(List<Book> books);
  Future<List<Book>> loadBooks();
  Future<bool> addBook(Book book, List<Book> currentBooks);
  Future<bool> removeBook(String bookId, List<Book> currentBooks);
  Future<bool> updateBook(Book book, List<Book> currentBooks);
  
  // Theme
  Future<bool> saveThemeMode(String mode);
  String? loadThemeMode();
  
  // First Launch
  bool get isFirstLaunch;
  Future<bool> markAsLaunched();
}
```

---

## 3. Offline-First Word Explanations (v1.1.0)

*Commit: `0da2604` - feat: Add offline-first word explanations with SQLite caching*

### 3.1 Overview

The offline-first architecture ensures that users can access word explanations even without an internet connection. All API responses are cached locally in a SQLite database, providing instant access to previously looked-up words.

**Key Benefits:**
- ✅ Works fully offline for saved books/words
- ✅ Instant responses for cached explanations
- ✅ Reduced API costs through intelligent caching
- ✅ Improved user experience with faster load times

### 3.2 Architecture

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

### 3.4 Services

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

### 3.5 Usage

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

### 3.6 Configuration

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

## 4. Context-Aware Rephrasing Levels (v1.1.0)

*Commit: `a9b810a` - feat: Add context-aware rephrasing levels*

### 4.1 Overview

The rephrasing levels feature allows users to customize the depth of word explanations based on their reading goals. Three levels are available, each with tailored AI prompts.

**Key Benefits:**
- ✅ Personalized reading experience
- ✅ Quick lookups for casual reading (Simple)
- ✅ Rich context for literary analysis (Deep)
- ✅ Persistent user preference

### 4.2 Explanation Levels

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

### 4.3 UI Components

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

### 4.4 Integration

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

### 4.5 Customization

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

## 5. Word Frequency Per Book (v1.2.0)

*Commit: feat: Add word frequency tracking per book*

### 5.1 Overview

The Word Frequency feature helps readers identify patterns in their vocabulary challenges. When users look up the same word multiple times, it indicates a persistent difficulty — these "challenging words" are tracked and displayed prominently.

**Key Benefits:**
- ✅ Identify words you struggle with most
- ✅ Academic feel with ranked vocabulary
- ✅ Zero distraction — minimal, elegant UI
- ✅ Per-book tracking for contextual insights
- ✅ Instant visibility without charts or complex visualizations

**Design Philosophy:**
> "Readers like seeing patterns in what they struggle with."

The feature provides insight without overwhelming — a simple ranked list with count badges, no charts needed.

### 5.2 How It Works

#### Lookup Count Tracking

Every time a user looks up the same word within a book:

1. **First lookup:** Word is added to collection with `lookupCount = 1`
2. **Subsequent lookups:** Existing word's `lookupCount` is incremented
3. **Explanation updated:** Latest explanation replaces the old one

```dart
// When explaining a word
final existingWordIndex = book.words.indexWhere(
  (w) => w.word.toLowerCase() == word.toLowerCase(),
);

if (existingWordIndex >= 0) {
  // Word exists - increment lookup count
  final existingWord = book.words[existingWordIndex];
  final updatedWord = existingWord.copyWith(
    explanation: newExplanation,
    lookupCount: existingWord.lookupCount + 1,
  );
  // Update book...
} else {
  // New word - create with lookupCount = 1
  final newWord = WordEntry(..., lookupCount: 1);
  // Add to book...
}
```

#### Case-Insensitive Matching

Words are matched case-insensitively:
- "Telescreen", "telescreen", "TELESCREEN" → all increment the same word

### 5.3 UI Components

#### WordFrequencyCard

**Location:** `lib/widgets/word_frequency_card.dart`

A collapsible card displaying top challenging words with visual ranking.

```dart
WordFrequencyCard(
  topWords: book.getTopDifficultWords(limit: 10),
  onWordTap: (word) => showWordDetails(word),
  isExpanded: _isFrequencyExpanded,
  onToggleExpand: () => setState(() => _isFrequencyExpanded = !_isFrequencyExpanded),
)
```

**Visual Elements:**

| Element | Description |
|---------|-------------|
| Header Icon | Trending up icon (📈) with primary color background |
| Title | "Challenging Words" |
| Subtitle | "Words you've looked up multiple times" |
| Word List | Ranked list with badges |
| Expand Button | "Show All X" / "Show Less" toggle |

#### Ranking Badges

Top 3 words receive special medal-style badges:

| Rank | Badge Color | Hex Values |
|------|-------------|------------|
| 🥇 1st | Gold | Background: `#D4AF37` @ 20%, Text: `#B8860B` |
| 🥈 2nd | Silver | Background: `#C0C0C0` @ 30%, Text: `#808080` |
| 🥉 3rd | Bronze | Background: `#CD7F32` @ 20%, Text: `#CD7F32` |
| 4th+ | Muted | Border color @ 50%, Muted text |

#### Count Badge

Each word displays its lookup count with an eye icon:

```dart
Container(
  child: Row(
    children: [
      Icon(Icons.visibility_outlined, size: 12),
      SizedBox(width: 4),
      Text('$count'),  // e.g., "5"
    ],
  ),
)
```

**High Frequency Styling:** Words with 5+ lookups get accent-colored badges.

### 5.4 Display Logic

#### When the Card Appears

The "Challenging Words" card is shown when:

```dart
if (topDifficultWords.isNotEmpty && widget.book.words.length >= 3)
```

| Condition | Card Shown? |
|-----------|-------------|
| Book has 0-2 words | ❌ No |
| Book has 3+ words | ✅ Yes |
| All words looked up once | ✅ Yes (shows top by recency) |
| Some words looked up 2+ times | ✅ Yes (prioritizes high counts) |

#### Display Limits

| State | Words Shown |
|-------|-------------|
| Collapsed (default) | Top 5 words |
| Expanded | Up to 10 words |
| Maximum tracked | Unlimited (all words in book) |

#### Sorting Algorithm

Words are sorted by:
1. **Primary:** Lookup count (descending)
2. **Secondary:** Timestamp (most recent first)

```dart
sorted.sort((a, b) {
  final countComparison = b.lookupCount.compareTo(a.lookupCount);
  if (countComparison != 0) return countComparison;
  return b.timestamp.compareTo(a.timestamp);
});
```

### 5.5 Data Model

#### WordEntry Updates

**Location:** `lib/models/word_entry.dart`

```dart
class WordEntry {
  final String id;
  final String word;
  final String explanation;
  final String bookId;
  final DateTime timestamp;
  final int lookupCount;  // NEW: Tracks lookup frequency

  // Constructor with default
  WordEntry({
    ...
    this.lookupCount = 1,  // Default to 1 for new words
  });

  // Increment helper
  WordEntry incrementLookup() {
    return copyWith(lookupCount: lookupCount + 1);
  }
}
```

#### Book Model Helpers

**Location:** `lib/models/book.dart`

```dart
class Book {
  /// Get words sorted by lookup count (most looked up first)
  List<WordEntry> getTopDifficultWords({int limit = 10}) {
    if (words.isEmpty) return [];
    
    final sorted = [...words];
    sorted.sort((a, b) {
      final countComparison = b.lookupCount.compareTo(a.lookupCount);
      if (countComparison != 0) return countComparison;
      return b.timestamp.compareTo(a.timestamp);
    });
    
    return sorted.take(limit).toList();
  }

  /// Check if book has any words looked up more than once
  bool get hasRepeatedWords => words.any((w) => w.lookupCount > 1);

  /// Get total lookups across all words
  int get totalLookups => words.fold(0, (sum, w) => sum + w.lookupCount);
}
```

#### JSON Persistence

Lookup count is persisted with each word:

```dart
// toJson
{
  'id': id,
  'word': word,
  'explanation': explanation,
  'bookId': bookId,
  'timestamp': timestamp.toIso8601String(),
  'lookupCount': lookupCount,  // NEW
}

// fromJson (with backward compatibility)
lookupCount: json['lookupCount'] as int? ?? 1,
```

**Backward Compatibility:** Existing words without `lookupCount` default to `1`.

---

## 6. API Reference

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

## 7. Project Architecture

### High-Level Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                         PRESENTATION                            │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │ SplashScreen │ │ LibraryScreen│ │ BookDetailScreen          │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
│  ┌──────────────┐                                               │
│  │ AddBookScreen│                                               │
│  └──────────────┘                                               │
├────────────────────────────────────────────────────────────────┤
│                          WIDGETS                                │
│  ┌────────────┐ ┌───────────────┐ ┌─────────────────────────┐  │
│  │  BookCard  │ │ WordListItem  │ │ ExplanationLevelSelector │  │
│  └────────────┘ └───────────────┘ └─────────────────────────┘  │
│  ┌────────────┐ ┌───────────────┐ ┌──────────────────────────┐ │
│  │LoadingDots │ │PrimaryButton  │ │WordExplanationSheet      │ │
│  └────────────┘ └───────────────┘ └──────────────────────────┘ │
├────────────────────────────────────────────────────────────────┤
│                         SERVICES                                │
│  ┌───────────────────┐ ┌───────────────────────────────────┐   │
│  │  PerplexityService│ │ WordExplanationCacheService       │   │
│  └───────────────────┘ └───────────────────────────────────┘   │
│  ┌───────────────────┐ ┌───────────────────────────────────┐   │
│  │  StorageService   │ │ ConnectivityService               │   │
│  └───────────────────┘ └───────────────────────────────────┘   │
│  ┌───────────────────┐                                         │
│  │  DatabaseService  │                                         │
│  └───────────────────┘                                         │
├────────────────────────────────────────────────────────────────┤
│                          DATA                                   │
│  ┌────────────┐ ┌─────────────┐ ┌────────────────────────────┐ │
│  │    Book    │ │  WordEntry  │ │     ExplanationLevel       │ │
│  └────────────┘ └─────────────┘ └────────────────────────────┘ │
├────────────────────────────────────────────────────────────────┤
│                        PERSISTENCE                              │
│  ┌───────────────────────────┐ ┌──────────────────────────┐    │
│  │    SharedPreferences      │ │     SQLite Database      │    │
│  │    (Settings, Theme)      │ │     (Cache, Books)       │    │
│  └───────────────────────────┘ └──────────────────────────┘    │
├────────────────────────────────────────────────────────────────┤
│                         EXTERNAL                                │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Perplexity AI API                      │ │
│  └───────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

### Data Flow

#### Word Explanation Flow

```
User enters word
       │
       ▼
BookDetailScreen
       │
       ├──► Check selected ExplanationLevel
       │
       ▼
PerplexityService.explainWord()
       │
       ├──► Generate cache key: "{word}_{level}"
       │
       ▼
WordExplanationCacheService.getExplanation()
       │
       ├─── CACHE HIT ───► Return cached result
       │
       ├─── CACHE MISS
       │
       ▼
ConnectivityService.isOnline?
       │
       ├─── OFFLINE ───► Return error/stale cache
       │
       ├─── ONLINE
       │
       ▼
Perplexity API HTTP Request
       │
       ├──► Parse response
       │
       ▼
WordExplanationCacheService.cacheExplanation()
       │
       ▼
Return result to UI
```

### State Management

Contexta uses a simple **lift-state-up** pattern without external state management libraries:

1. **App State (`main.dart`):** Books list, theme mode, services
2. **Screen State:** Screen-specific UI state (loading, form inputs)
3. **Widget State:** Animation controllers, transient UI state

```dart
// App-level state in main.dart
class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  List<Book> _books = [];
  final StorageService _storage = StorageService();
  
  // State passed down via Navigator arguments
  // Callbacks passed up via Navigator.pop(result)
}
```

---

## 8. Troubleshooting

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

## 9. Changelog

All notable changes to Contexta are documented here.

### [1.2.0] - 2026-01-30

#### Added - Word Frequency Per Book
*Commit: feat: Add word frequency tracking per book*

- **Lookup Count Tracking**
  - `lookupCount` field added to WordEntry model
  - Increments each time same word is looked up
  - Case-insensitive word matching
  - Backward compatible (defaults to 1 for existing words)

- **WordFrequencyCard Widget**
  - Collapsible card showing top challenging words
  - Gold/Silver/Bronze ranking badges for top 3
  - Eye icon with count badge per word
  - Expand/collapse to show 5 or 10 words
  - Smooth animations (300ms, easeOutCubic)
  - Full dark/light theme support

- **Book Model Helpers**
  - `getTopDifficultWords(limit)`: Get words sorted by frequency
  - `hasRepeatedWords`: Check if any word looked up 2+ times
  - `totalLookups`: Sum of all lookup counts

- **Smart Display Logic**
  - Card appears when book has 3+ words
  - Words sorted by frequency, then recency
  - Tapping word opens full explanation sheet

---

### [1.1.0] - 2026-01-30

#### Added - Offline-First Word Explanations
*Commit: `0da2604`*

- **SQLite Database Layer**
  - DatabaseService singleton with migration support
  - Tables: `books`, `word_entries`, `word_explanation_cache`, `sync_queue`
  - Indexed for fast lookups
  
- **Word Explanation Cache Service**
  - LRU (Least Recently Used) cache eviction
  - 10,000 entry maximum with automatic cleanup
  - 1-year expiration on cached entries
  - Cache statistics tracking (hit count, last accessed)

- **Connectivity Service**
  - Real-time network status monitoring
  - Stream-based status updates
  - Graceful offline/online transitions

- **Updated PerplexityService**
  - Cache-first lookup strategy
  - Automatic caching of API responses
  - Offline fallback to cached data

#### Added - Context-Aware Rephrasing Levels
*Commit: `a9b810a`*

- **ExplanationLevel Enum**
  - `Simple` (◯): 3-4 word definitions, 150 tokens
  - `Literary` (◐): Contextual depth, 300 tokens
  - `Deep` (●): Etymology + analysis, 500 tokens

- **ExplanationLevelSelector Widget**
  - Animated segmented control
  - Smooth sliding indicator
  - Haptic feedback
  - Dark/Light theme support

- **Level Persistence**
  - User preference saved in SharedPreferences
  - Restored on app launch

- **Level-Aware Caching**
  - Separate cache entries per level
  - Cache key format: `{word}_{level}`

---

### [1.0.1] - 2026-01-28

#### Fixed
*Commit: `0e70ec4` - fix: improve word edit keyboard handling*

- Fixed keyboard handling when editing words
- Improved focus management in BookDetailScreen

---

### [1.0.0] - 2026-01-27

*Commit: `cdaf3e8` - Initial commit: Contexta reading companion app*

#### Added - Core Application
- **Personal Library System**
  - Add/remove books with title and author
  - Visual book cards with stacked paper effect
  - Persistent storage via SharedPreferences
  - Empty state with branded illustration

- **Contextual Word Explanations**
  - Perplexity AI integration (sonar model)
  - Context-aware explanations based on book
  - Short definition + detailed context format
  - 30-second timeout handling

- **Word Collection Management**
  - Per-book word collections
  - Add, edit, remove words
  - Sort: Recent, Oldest, A-Z, Z-A
  - Relative timestamps ("2h ago")

- **Theme System**
  - Light mode (warm beige aesthetic)
  - Dark mode (deep parchment)
  - Persistent theme preference
  - Smooth 300ms transitions

- **Design System**
  - Georgia serif + Inter sans-serif typography
  - Consistent border radius scale (8-28px)
  - Animation system with defined durations
  - Custom widget library (12 components)

- **UI Components**
  - BookCard with press/hover animations
  - LoadingDots animated indicator
  - ContextaLogo with CustomPaint
  - WordExplanationSheet modal
  - Primary/Secondary buttons
  - Styled text fields and dialogs

- **Splash Screen**
  - Animated logo reveal
  - 2-second display before navigation
  - First-launch detection

---

## Appendix

### Complete File Structure

```
lib/
├── main.dart                         # App entry, theme management
├── config/
│   └── api_config.dart               # Perplexity API configuration
├── models/
│   ├── book.dart                     # Book data model
│   ├── word_entry.dart               # Word entry model
│   └── explanation_level.dart        # Explanation levels enum (v1.1.0)
├── screens/
│   ├── splash_screen.dart            # Animated splash
│   ├── library_screen.dart           # Main library view
│   ├── book_detail_screen.dart       # Word input & collection
│   └── add_book_screen.dart          # Add book form
├── services/
│   ├── database/                     # Database module (v1.1.0)
│   │   ├── database.dart             # Barrel export
│   │   ├── database_service.dart     # SQLite operations
│   │   └── migrations.dart           # Schema migrations
│   ├── connectivity_service.dart     # Network status (v1.1.0)
│   ├── perplexity_service.dart       # AI API integration
│   ├── storage_service.dart          # SharedPreferences
│   └── word_explanation_cache_service.dart  # LRU cache (v1.1.0)
├── theme/
│   └── app_theme.dart                # Design tokens, colors
└── widgets/
    ├── book_card.dart                # Library book cards
    ├── contexta_app_bar.dart         # Custom app bar
    ├── contexta_bottom_sheet.dart    # Modal sheets
    ├── contexta_dialog.dart          # Confirmation dialogs
    ├── contexta_text_field.dart      # Styled inputs
    ├── explanation_level_selector.dart  # Level picker (v1.1.0)
    ├── loading_dots.dart             # Loading indicator
    ├── logo.dart                     # Brand logo
    ├── primary_button.dart           # Primary CTA
    ├── secondary_button.dart         # Secondary actions
    ├── word_explanation_sheet.dart   # Word detail modal
    ├── word_frequency_card.dart      # Challenging words card (v1.2.0)
    └── word_list_item.dart           # Word list rows
```

### All Dependencies

```yaml
# pubspec.yaml - Complete list
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8         # iOS-style icons
  shared_preferences: ^2.2.2      # Local key-value storage
  http: ^1.2.2                    # HTTP client for API
  flutter_dotenv: ^5.1.0          # Environment variables
  sqflite: ^2.4.2                 # SQLite database (v1.1.0)
  path: ^1.9.1                    # Path utilities (v1.1.0)
  connectivity_plus: ^6.1.4       # Network status (v1.1.0)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0           # Lint rules
```

### Environment Setup

1. Clone repository
2. Create `.env` file in project root:
   ```env
   PERPLEXITY_API_KEY=pplx-xxxxxxxxxxxxxxxxxx
   ```
3. Run `flutter pub get`
4. Run `flutter run`

### Getting API Key

1. Visit https://www.perplexity.ai/settings/api
2. Create new API key
3. Add to `.env` file

---

*This documentation covers Contexta from initial release through v1.1.0. For the latest updates, refer to the git commit history.*

*Last updated: January 30, 2026*
