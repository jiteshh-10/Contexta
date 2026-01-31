# Contexta - Complete Feature Documentation

> **Version:** 1.11.0  
> **Last Updated:** January 31, 2026  
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
6. [Difficulty Reason Tags (v1.3.0)](#6-difficulty-reason-tags-v130)
   - [Overview](#61-overview)
   - [Difficulty Reasons](#62-difficulty-reasons)
   - [UI Components](#63-ui-components)
   - [Integration](#64-integration)
   - [Data Model](#65-data-model)
7. [Global Search Across Books (v1.4.0)](#7-global-search-across-books-v140)
   - [Overview](#71-overview)
   - [UI Components](#72-ui-components)
   - [Search Logic](#73-search-logic)
   - [Integration](#74-integration)
8. [Export Words (v1.5.0)](#8-export-words-v150)
   - [Overview](#81-overview)
   - [Export Formats](#82-export-formats)
   - [UI Components](#83-ui-components)
   - [Services](#84-services)
   - [Integration](#85-integration)
9. [Reading Streak (v1.6.0)](#9-reading-streak-v160)
   - [Overview](#91-overview)
   - [Core Concept](#92-core-concept)
   - [UI Components](#93-ui-components)
   - [Services](#94-services)
   - [Settings](#95-settings)
   - [Database](#96-database)
10. [Quote Capture (v1.7.0)](#10-quote-capture-v170)
    - [Overview](#101-overview)
    - [Core Concept](#102-core-concept)
    - [UI Components](#103-ui-components)
    - [Data Model](#104-data-model)
    - [Database](#105-database)
11. [Dark Mode Refinement (v1.8.0)](#11-dark-mode-refinement-v180)
    - [Overview](#111-overview)
    - [Design Philosophy](#112-design-philosophy)
    - [Color System](#113-color-system)
    - [Shadow Strategy](#114-shadow-strategy)
    - [Helper Methods](#115-helper-methods)
    - [Updated Components](#116-updated-components)
12. [Shelf Interaction (v1.9.0)](#12-shelf-interaction-v190)
    - [Overview](#121-overview)
    - [Core Concept](#122-core-concept)
    - [Animation System](#123-animation-system)
    - [Components](#124-components)
    - [User Journey](#125-user-journey)
    - [Technical Details](#126-technical-details)
13. [Gentle Suggestions (v1.10.0)](#13-gentle-suggestions-v1100)
    - [Overview](#131-overview)
    - [Core Principle](#132-core-principle)
    - [Author Name Suggestions](#133-author-name-suggestions)
    - [Word Spelling Suggestions](#134-word-spelling-suggestions)
    - [Services](#135-services)
    - [UI Components](#136-ui-components)
    - [Animation & Micro-interactions](#137-animation--micro-interactions)
    - [Copy Tone Guidelines](#138-copy-tone-guidelines)
14. [Book Suggestions (v1.11.0)](#14-book-suggestions-v1110)
    - [Overview](#141-overview)
    - [Core Philosophy](#142-core-philosophy)
    - [Entry Point](#143-entry-point)
    - [Empty Shelf State](#144-empty-shelf-state)
    - [Suggestions State](#145-suggestions-state)
    - [Services](#146-services)
    - [UI Components](#147-ui-components)
    - [Animation & Timing](#148-animation--timing)
    - [Copy Tone Guidelines](#149-copy-tone-guidelines)
15. [API Reference](#15-api-reference)
16. [Project Architecture](#16-project-architecture)
17. [Troubleshooting](#17-troubleshooting)
18. [Changelog](#18-changelog)

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

## 6. Difficulty Reason Tags (v1.3.0)

*Feature: Optional tagging for why a word was difficult*

### 6.1 Overview

When looking up a word, readers often have specific reasons why it tripped them up. The Difficulty Reason feature lets users optionally tag **why** a word was challenging, adding a personal learning dimension to their vocabulary journey.

#### Key Principles

- **Optional & Skippable**: Never forces users to tag - it's entirely optional
- **Lightweight**: Quick single-tap selection, doesn't interrupt flow
- **Thoughtful**: Makes Contexta feel like a personal learning journal
- **Subtle UI**: Poppy animations without being distracting

### 6.2 Difficulty Reasons

Four carefully chosen categories cover the main reasons readers pause at words:

| Reason | Icon | Color | Use Case |
|--------|------|-------|----------|
| **Meaning unclear** | `help_outline_rounded` | Blue (#5B8DEF) | Word meaning itself was unfamiliar |
| **Context confusing** | `menu_book_rounded` | Orange (#E89B3E) | Knew the word but context made it confusing |
| **Philosophical** | `psychology_outlined` | Purple (#9B6EE8) | Deep or abstract philosophical usage |
| **Old/Archaic** | `history_edu_rounded` | Teal (#6EAE8B) | Dated or archaic language |

```dart
enum DifficultyReason {
  meaningUnclear(
    label: 'Meaning unclear',
    description: 'The word meaning itself was unfamiliar',
    icon: Icons.help_outline_rounded,
    color: Color(0xFF5B8DEF),
  ),
  contextConfusing(
    label: 'Context confusing',
    description: 'I knew the word but the context made it confusing',
    icon: Icons.menu_book_rounded,
    color: Color(0xFFE89B3E),
  ),
  philosophicalUsage(
    label: 'Philosophical',
    description: 'The word was used in a deep or philosophical way',
    icon: Icons.psychology_outlined,
    color: Color(0xFF9B6EE8),
  ),
  archaicUsage(
    label: 'Old/Archaic',
    description: 'The word or usage felt dated or archaic',
    icon: Icons.history_edu_rounded,
    color: Color(0xFF6EAE8B),
  );

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  
  // Serialization for storage
  String toStorageString() => name;
  static DifficultyReason? fromStorageString(String? value) {...}
}
```

### 6.3 UI Components

#### DifficultyReasonSelector

The main selection widget with animated chip buttons:

```dart
DifficultyReasonSelector(
  selectedReason: _selectedReason,
  onReasonChanged: (reason) => setState(() => _selectedReason = reason),
  onSkip: () => Navigator.pop(context),
  showHeader: true,  // Shows "Why was this tricky?"
)
```

**Animation Details:**
- **Entrance**: Elastic staggered animation (150ms delay per chip, 600ms total)
- **Selection**: Bounce effect (300ms, 10% scale pop)
- **Press**: Scale down 5% on tap

**Visual States:**
- Unselected: Muted background, border matches theme
- Selected: Colored background tint, colored border, checkmark icon, subtle shadow

#### DifficultyReasonBadge

Compact display for lists and detail views:

```dart
// Full badge (icon + label)
DifficultyReasonBadge(reason: DifficultyReason.meaningUnclear)

// Compact badge (icon only, for list items)
DifficultyReasonBadge(reason: entry.difficultyReason!, compact: true)
```

### 6.4 Integration

#### In WordExplanationSheet

The sheet shows different states based on whether a reason is set:

1. **Has Reason**: Shows `DifficultyReasonBadge` (tappable to edit)
2. **No Reason + Editable**: Shows "Add difficulty note" button
3. **Editing Mode**: Shows full `DifficultyReasonSelector`

```dart
// State management in WordExplanationSheet
bool _isEditingReason = false;
DifficultyReason? _selectedReason;

void _toggleReasonEditing() {
  setState(() {
    _isEditingReason = !_isEditingReason;
    if (!_isEditingReason && _selectedReason != widget.entry.difficultyReason) {
      // Auto-save when closing editor
      final updatedEntry = widget.entry.copyWith(
        difficultyReason: _selectedReason,
        clearDifficultyReason: _selectedReason == null,
      );
      widget.onUpdate?.call(updatedEntry);
    }
  });
}
```

#### In WordListItem

Shows compact badge next to word title:

```dart
Row(
  children: [
    Expanded(child: Text(widget.entry.capitalizedWord, ...)),
    if (widget.entry.difficultyReason != null) ...[
      const SizedBox(width: 8),
      DifficultyReasonBadge(
        reason: widget.entry.difficultyReason!,
        compact: true,
      ),
    ],
  ],
)
```

### 6.5 Data Model

#### WordEntry Updates

```dart
class WordEntry {
  final String id;
  final String word;
  final String explanation;
  final String bookId;
  final DateTime timestamp;
  final int lookupCount;
  final DifficultyReason? difficultyReason;  // NEW - Optional

  WordEntry copyWith({
    // ... other fields
    DifficultyReason? difficultyReason,
    bool clearDifficultyReason = false,  // Set to true to clear reason
  }) {
    return WordEntry(
      // ... other fields
      difficultyReason: clearDifficultyReason 
          ? null 
          : (difficultyReason ?? this.difficultyReason),
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    // ... other fields
    'difficultyReason': difficultyReason?.toStorageString(),
  };

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
    // ... other fields
    difficultyReason: DifficultyReason.fromStorageString(
      json['difficultyReason'] as String?,
    ),
  );
}
```

**Backward Compatibility:** Existing words without `difficultyReason` will have `null` (no reason set).

---

## 7. Global Search Across Books (v1.4.0)

*Feature: Search words across your entire library*

### 7.1 Overview

As users build their vocabulary collection (50+ words), scrolling through individual books becomes impractical. Global Search provides a fast, elegant way to find any word across all books instantly.

#### Key Principles

- **Instant Results**: No delay, filters as you type
- **Bookish Design**: Bookmark-style ribbon animation
- **Context Aware**: Shows which book each word belongs to
- **Subtle & Sleek**: Appears only when there are words to search

#### Why This Feature

| Without Search | With Search |
|----------------|-------------|
| Open each book manually | Type a few letters |
| Scroll through long lists | See matching words instantly |
| Forget which book had a word | Book context shown in results |

### 7.2 UI Components

#### GlobalSearchBar

The main search component with bookmark-inspired animations:

```dart
GlobalSearchBar(
  books: widget.books,
  onResultTap: (result) {
    // Navigate to book and show word
    _handleSearchResult(result);
  },
)
```

**Animation Details:**
- **Expand**: 350ms with easeOutCubic curve
- **Bookmark Ribbon**: Slides in from left with easeOutBack (overshoot)
- **Results**: 250ms fade + slide from top
- **Focus**: Border color transitions to primary with glow

**Visual States:**
- Collapsed: Muted placeholder "Search words"
- Expanded: Active input with blue ribbon indicator
- With Results: Dropdown with matching words
- Empty Results: "No words found" message

#### SearchResult Model

Links a word to its parent book:

```dart
class SearchResult {
  final WordEntry word;
  final Book book;
}
```

#### _SearchResultItem

Individual result with word highlighting:

```dart
// Features:
// - Bookmark-style left ribbon
// - Word with query highlighted in primary color
// - Book title with book icon
// - Difficulty badge if present
// - Chevron for navigation affordance
```

#### _HighlightedWord

Highlights matching query substring:

```dart
_HighlightedWord(
  word: "Ephemeral",
  query: "phem",
)
// Renders: E[phem]eral with [phem] highlighted
```

### 7.3 Search Logic

#### Filtering Algorithm

```dart
void _onSearchChanged() {
  final query = _controller.text.trim().toLowerCase();
  
  // Search across all books
  final results = <SearchResult>[];
  for (final book in widget.books) {
    for (final word in book.words) {
      if (word.word.toLowerCase().contains(query)) {
        results.add(SearchResult(word: word, book: book));
      }
    }
  }
  
  // Sort by relevance
  results.sort((a, b) {
    // Exact matches first
    final aExact = a.word.word.toLowerCase() == query;
    final bExact = b.word.word.toLowerCase() == query;
    if (aExact && !bExact) return -1;
    if (!aExact && bExact) return 1;
    // Then by recency
    return b.word.timestamp.compareTo(a.word.timestamp);
  });
  
  // Limit to 10 results
  setState(() => _results = results.take(10).toList());
}
```

**Search Characteristics:**
- Case-insensitive substring matching
- Searches word text only (not explanations)
- Maximum 10 results displayed
- Exact matches prioritized
- Secondary sort by timestamp (most recent first)

### 7.4 Integration

#### In LibraryScreen

The search bar appears at the top of the library when books have words:

```dart
Widget _buildBookListWithSearch(bool showSearch) {
  return Column(
    children: [
      // Global search bar (only show if there are words to search)
      if (showSearch)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: GlobalSearchBar(
            books: widget.books,
            onResultTap: _handleSearchResult,
          ),
        ),
      
      // Book list
      Expanded(child: _buildBookList()),
    ],
  );
}
```

#### Handling Search Results

When a user taps a search result:

```dart
void _handleSearchResult(SearchResult result) {
  setState(() {
    _selectedBook = result.book;
    _pendingWordToShow = result.word;
    _view = LibraryView.detail;
  });
}

// In build(), after navigating to detail:
if (_pendingWordToShow != null) {
  final wordToShow = _pendingWordToShow!;
  _pendingWordToShow = null;
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _showWordDetails(wordToShow, currentBook);
    }
  });
}
```

This pattern:
1. Navigates to the book's detail screen
2. Automatically opens the word explanation sheet
3. Clears the pending word to prevent re-showing

### Files Structure

```
lib/
├── widgets/
│   └── global_search.dart           # NEW
│       ├── SearchResult             # Model
│       ├── GlobalSearchBar          # Main widget
│       ├── _SearchResultItem        # Result item
│       └── _HighlightedWord         # Text highlighter
└── screens/
    └── library_screen.dart          # MODIFIED
        ├── _handleSearchResult()    # NEW
        ├── _showWordDetails()       # NEW
        └── _pendingWordToShow       # NEW state
```

---

## 8. Export Words (v1.5.0)

*Feature: Share your vocabulary collection as text or markdown*

### 8.1 Overview

Export lets users share their curated vocabulary collection with others or archive it externally. Built with "serious reader appeal" — minimal UI, powerful output.

#### Key Principles

- **Two Formats**: Plain text (.txt) and Markdown (.md)
- **Two Scopes**: Per-book or entire library
- **Native Share**: Uses device share intent for universal compatibility
- **Instant Preview**: See what you're exporting before sharing
- **Zero Friction**: One tap to export, one tap to share

#### Why This Feature

| Use Case | Export Solution |
|----------|-----------------|
| Share vocabulary with study partner | Export as markdown, share via messaging |
| Backup words before device change | Export all books, save to cloud |
| Create flashcards in another app | Plain text format, copy to Anki |
| Review words on paper | Markdown renders beautifully when printed |
| Keep a professional archive | PDF with proper formatting and pagination |

### 8.2 Export Formats

#### ExportFormat Enum

**Location:** `lib/services/export_service.dart`

```dart
enum ExportFormat {
  plainText('Plain Text', 'txt', 'text/plain'),
  markdown('Markdown', 'md', 'text/markdown'),
  pdf('PDF Document', 'pdf', 'application/pdf');

  final String label;
  final String extension;
  final String mimeType;
}
```

#### Plain Text Output

Clean, ASCII-styled format for maximum compatibility:

```
══════════════════════════════════════════════════════════
     VOCABULARY COLLECTION
     The Brothers Karamazov by Fyodor Dostoevsky
══════════════════════════════════════════════════════════

📚 Total Words: 5
📅 Exported: January 30, 2026

──────────────────────────────────────────────────────────

1. EPHEMERAL
   Definition: Brief, short-lived
   
   Context: In the context of Dostoevsky's exploration of 
   suffering and redemption...
   
   Encountered: 3 times
   Added: January 30, 2026

──────────────────────────────────────────────────────────

2. NIHILISM
   ...
```

#### Markdown Output

Rich formatting for notes apps, Obsidian, Notion, etc.:

```markdown
# 📚 Vocabulary Collection

## The Brothers Karamazov
*by Fyodor Dostoevsky*

> **5 words** collected  
> Exported: January 30, 2026

---

### Ephemeral
*Added: January 30, 2026 • Encountered 3 times*

**Definition:** Brief, short-lived

**Context:** In the context of Dostoevsky's exploration...

> 💭 *Difficulty: Philosophical usage*

---

### Nihilism
...
```

#### PDF Output

Professional document format with:
- **Cover page** for multi-book exports with title and word count
- **Page headers** with book title and author
- **Page numbers** in footer
- **Styled word cards** with background, proper spacing
- **Difficulty and frequency badges** when available

**Technical Details:**
- Uses `pdf` package (dart_pdf) for pure Dart PDF generation
- A4 page format with 40pt margins
- Multi-page support with automatic pagination
- Works on all platforms (mobile, web, desktop)

### 8.3 UI Components

#### ExportOptionsSheet

**Location:** `lib/widgets/export_options_sheet.dart`

Bottom sheet with format selection and preview:

```dart
ExportOptionsSheet(
  book: currentBook,           // For single book export
  // OR
  books: allBooks,             // For all books export
  onClose: () => Navigator.pop(context),
)
```

**Features:**
- Format selection cards with animated border
- Toggle preview with expand animation
- Preview limited to 500 characters
- Share button with loading state
- Success/error feedback via snackbar

**Animation Details:**
- Format selection: 200ms border color transition
- Preview expand: 300ms height animation
- Button press: 0.96 scale with haptic feedback
- Loading: Three-dot animated indicator

#### _FormatOption Widget

Format selection card with radio-button behavior:

```dart
_FormatOption(
  format: ExportFormat.markdown,
  isSelected: _selectedFormat == ExportFormat.markdown,
  onTap: () => setState(() => _selectedFormat = ExportFormat.markdown),
)
```

**Visual States:**
- Unselected: Muted border, gray icon
- Selected: Primary border, primary icon, subtle background tint

#### _ExportButton (BookDetailScreen)

Icon button in collection header for per-book export:

```dart
_ExportButton(onTap: _showExportOptions)
```

**Design:** iOS-style share icon, matches sort button style

#### _ExportAllButton (LibraryScreen)

Icon button in app bar for full library export:

```dart
_ExportAllButton(onTap: _showExportAllOptions)
```

**Design:** Circular button, appears only when books have words

### 8.4 Services

#### ExportService

**Location:** `lib/services/export_service.dart`

Singleton service handling content generation and file sharing:

```dart
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  
  /// Export and share via native share intent
  Future<ExportResult> exportAndShare({
    required ExportFormat format,
    required ExportScope scope,
    Book? book,                    // Required for singleBook scope
    List<Book>? books,             // Required for allBooks scope
  });
  
  /// Get preview content (truncated)
  String previewContent({
    required ExportFormat format,
    required ExportScope scope,
    Book? book,
    List<Book>? books,
    int maxLength = 500,
  });
}
```

#### ExportResult

Result model for export operations:

```dart
class ExportResult {
  final bool success;
  final String? filePath;     // Path to generated file
  final int wordCount;        // Total words exported
  final String? error;        // Error message if failed
}
```

#### ExportScope Enum

```dart
enum ExportScope {
  singleBook,     // Export one book's words
  allBooks,       // Export entire library
}
```

#### File Naming

Generated filenames are human-readable and collision-resistant:

```dart
String _generateFileName(String title, ExportFormat format) {
  final sanitized = title
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');
  final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return '${sanitized}_words_$date.${format.extension}';
}
```

**Examples:**
- `the_brothers_karamazov_words_2026-01-30.md`
- `contexta_vocabulary_2026-01-30.txt`

### 8.5 Integration

#### In BookDetailScreen

Export button appears in collection header next to sort button:

```dart
// In _buildCollectionHeader()
if (widget.book.words.isNotEmpty) ...[
  const SizedBox(width: 8),
  _ExportButton(onTap: _showExportOptions),
  const SizedBox(width: 8),
  _SortButton(currentSort: _sortOption, onTap: _showSortOptions),
],
```

Method to show export sheet:

```dart
void _showExportOptions() {
  showContextaBottomSheet(
    context: context,
    child: ExportOptionsSheet(
      book: widget.book,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}
```

#### In LibraryScreen

Export all button in app bar when library has words:

```dart
// In build()
appBar: ContextaAppBar(
  title: 'My Books',
  showBackButton: false,
  rightAction: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (hasAnyWords)
        _ExportAllButton(onTap: _showExportAllOptions),
      const SizedBox(width: 4),
      _ThemeToggleButton(
        isDarkMode: widget.isDarkMode,
        onTap: widget.onToggleTheme,
      ),
    ],
  ),
),
```

Method to show export all sheet:

```dart
void _showExportAllOptions() {
  showContextaBottomSheet(
    context: context,
    child: ExportOptionsSheet(
      books: widget.books,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}
```

### Files Structure

```
lib/
├── services/
│   └── export_service.dart          # NEW
│       ├── ExportFormat             # Enum
│       ├── ExportScope              # Enum
│       ├── ExportResult             # Model
│       └── ExportService            # Singleton
├── widgets/
│   └── export_options_sheet.dart    # NEW
│       ├── ExportOptionsSheet       # Main widget
│       ├── _FormatOption            # Format card
│       ├── _ExportButton            # Share button
│       └── _CloseButton             # Close button
└── screens/
    ├── book_detail_screen.dart      # MODIFIED
    │   ├── _showExportOptions()     # NEW
    │   └── _ExportButton            # NEW widget
    └── library_screen.dart          # MODIFIED
        ├── _showExportAllOptions()  # NEW
        └── _ExportAllButton         # NEW widget
```

### Dependencies Added

```yaml
# pubspec.yaml
dependencies:
  share_plus: ^10.1.4      # Native share intent
  path_provider: ^2.1.5    # Temporary file storage
```

---

## 9. Reading Streak (v1.6.0)

### 9.1 Overview

The Reading Streak feature provides a **subtle consistency indicator** that respects irregular reading patterns while encouraging users to return to their reading journey. Unlike traditional streak trackers that create daily pressure, Contexta's approach affirms continuity without demanding discipline.

**Core Philosophy:**
- Not a habit tracker
- Not daily streak pressure
- Not a productivity metric
- Exists to **affirm continuity**, not demand discipline

### 9.2 Core Concept

#### What It Measures

A **"reading day"** = at least one word saved on that calendar day.
Multiple words on the same day count as **one** reading day.

**Example:**
- Monday → saved 3 words
- Wednesday → saved 1 word
- Friday → saved 5 words

Display: *"Words noted on 3 different days"*

#### Streak Logic

```dart
class ReadingStreakData {
  /// Total number of unique active reading days
  final int totalActiveDays;
  
  /// Current consecutive streak (for future use)
  final int currentStreak;
  
  /// Recent days for dot visualization (last 7 days)
  final List<ReadingDay> recentDays;
  
  /// Pre-formatted display text
  final String displayText;
  
  /// Whether a new day was just added (for animation)
  final bool isNewDayAdded;
}

class ReadingDay {
  final DateTime date;
  final bool isActive;
}
```

### 9.3 UI Components

#### ReadingStreakIndicator Widget

**Location:** `lib/widgets/reading_streak_indicator.dart`

```dart
const ReadingStreakIndicator({
  super.key,
  this.showDotRow = true,  // Whether to show mini dot row
});
```

**Visual Design:**
```
───────────────
✦  Words noted on 3 different days
● ● ○ ●
───────────────
```

**Typography:**
- Serif font
- Slightly smaller than body text (13px)
- Color: text-muted
- Italic style

**Container:**
- No card, no border, no background
- Just text and breathing space

#### Mini Dot Row (Optional)

```dart
class _DotRow extends StatelessWidget {
  final List<ReadingDay> days;
  // Each dot = a reading day
  // Filled = day with at least one word
  // Max 7 dots visible (rolling window)
}
```

**Rules:**
- Muted color
- No labels
- No interaction

#### Animation Design

**1. Entry Animation (First appearance)**
```dart
// Fade-in + upward translate
_fadeAnimation = Tween<double>(begin: 0.0, end: 1.0);
_slideAnimation = Tween<Offset>(
  begin: const Offset(0, 0.2),
  end: Offset.zero,
);
// Duration: 300ms, Curve: ease-out
```

**2. Increment Animation (New day added)**
```dart
// Text briefly dims, number updates, returns to normal
AnimatedOpacity(
  duration: const Duration(milliseconds: 200),
  opacity: _isAnimatingIncrement ? 0.6 : 1.0,
  child: content,
);
```

**3. Haptic Feedback**
- Very light vibration (HapticFeedback.lightImpact)
- Only on *new day added*, not every word

#### Copy Variants

Rotate occasionally for variety:
- "Words noted on {count} different days"
- "You've returned to reading on {count} days"
- "Your notes span {count} reading days"

### 9.4 Services

#### ReadingStreakService

**Location:** `lib/services/reading_streak_service.dart`

```dart
class ReadingStreakService {
  // Singleton pattern
  static final ReadingStreakService _instance = ReadingStreakService._internal();
  factory ReadingStreakService() => _instance;

  /// Stream of streak data updates
  Stream<ReadingStreakData> get streakStream;

  /// Initialize the service
  Future<void> initialize();

  /// Record a reading day (call when a word is saved)
  Future<void> recordReadingDay();

  /// Get current streak data
  Future<ReadingStreakData> getStreakData();

  /// Dispose resources
  void dispose();
}
```

**Integration in BookDetailScreen:**
```dart
// When a new word is added:
updatedBook = widget.book.addWord(newWord);

// Record reading day for streak tracking
ReadingStreakService().recordReadingDay();
```

### 9.5 Settings

#### SettingsSheet Widget

**Location:** `lib/widgets/settings_sheet.dart`

```dart
class SettingsSheet extends StatefulWidget {
  final bool showReadingStreak;
  final VoidCallback onToggleReadingStreak;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onClose;
  final List<Book> books;
  final VoidCallback onExportAll;
}
```

**Settings Options:**

1. **Theme Mode Toggle**
   - Title: "Light mode" / "Dark mode" (dynamic)
   - Description: "Switch between light and dark appearance"
   - Toggles app theme immediately

2. **Reading Consistency Toggle**
   - Title: "Show reading consistency"
   - Description: "Display a subtle indicator of your reading activity"
   - Default: **ON**
   - Stored in SharedPreferences

3. **Export All Words Action**
   - Title: "Export all words"
   - Description: "Export vocabulary from all books"
   - Only visible when books have words
   - Opens ExportOptionsSheet

**Implementation Notes:**
- Uses StatefulWidget for immediate toggle feedback
- Local state mirrors props for instant UI updates
- Calls parent callbacks to persist changes

#### StorageService Integration

```dart
// Storage keys
static const String _showReadingStreakKey = 'contexta_show_reading_streak';

// Save reading streak visibility preference
Future<bool> saveShowReadingStreak(bool show);

// Load reading streak visibility preference (default: true)
bool loadShowReadingStreak();
```

### 9.6 Database

#### Migration v1 → v2

**Location:** `lib/services/database/migrations.dart`

```dart
static Future<void> _migrateV1ToV2(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS reading_days (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_reading_days_date 
    ON reading_days (date DESC)
  ''');
}
```

**Schema:**
- `date`: TEXT (yyyy-MM-dd format, local timezone)
- `created_at`: TEXT (ISO 8601 timestamp)

### 9.7 File Structure

```
lib/
├── services/
│   ├── reading_streak_service.dart   # NEW
│   ├── storage_service.dart          # MODIFIED (settings)
│   └── database/
│       ├── database_service.dart     # MODIFIED (version 2)
│       └── migrations.dart           # MODIFIED (v2 migration)
├── widgets/
│   ├── reading_streak_indicator.dart # NEW
│   └── settings_sheet.dart           # NEW
├── screens/
│   ├── library_screen.dart           # MODIFIED
│   │   ├── ReadingStreakIndicator    # Integrated
│   │   ├── _SettingsButton           # NEW widget
│   │   └── _showSettings()           # NEW method
│   └── book_detail_screen.dart       # MODIFIED
│       └── recordReadingDay()        # Called on word add
└── main.dart                         # MODIFIED
    ├── ReadingStreakService init     # Initialized
    └── showReadingStreak state       # Managed
```

### 9.8 Psychology & Design Rationale

**Why This Works:**
- Encourages return without guilt
- Rewards *presence*, not frequency
- Feels reflective, not competitive
- Aligns with how real readers read

**What This Feature Is NOT:**
❌ Not a habit tracker
❌ Not daily streak pressure
❌ Not a productivity metric
❌ Not visible everywhere

It exists to **affirm continuity**, not demand discipline.

---

## 10. Quote Capture (v1.7.0)

### 10.1 Overview

Words are rarely remembered alone.
They are remembered **inside a sentence**, a rhythm, a moment in the text.

Quote Capture lets readers preserve *where* the word lived—
not to study harder, but to **remember better**.

**Core Philosophy:**
- This is not highlighting
- This is *a margin note*
- Optional, never forced
- Feels like underlining in a paperback

### 10.2 Core Concept

#### What It Is

* A quote is a **single sentence or short passage** where the word appeared.
* It is **optional**.
* It is stored **with the word**, not separately.

#### When the Quote Is Added

**Primary Flow (Default)**
1. User enters a word
2. Explanation is generated
3. Word is saved
4. Quote field remains **hidden**

**Secondary Flow (Intentional)**
User taps: *"Add the sentence it appeared in"*
Only then does the quote input appear.

This keeps the interface clean for most users.

### 10.3 UI Components

#### QuoteCaptureSection Widget

**Location:** `lib/widgets/quote_capture_section.dart`

```dart
class QuoteCaptureSection extends StatefulWidget {
  final String? quote;
  final bool startInEditMode;
  final void Function(String? quote) onQuoteChanged;
  final bool canEdit;
}
```

#### Default State (Collapsed)

A single muted line:
> *"Add the sentence it appeared in"*

* Italic
* Muted text color
* No border
* Looks like a pencil note prompt

#### Expanded State (Editing)

**Input Style**
* Multiline text area
* Rounded corners
* Paper background
* Slight inset padding

**Placeholder**
> "Write the sentence as you remember it…"

#### Typography

* Serif font (same as explanation)
* Slightly smaller than explanation text
* Line height increased
* Text color: secondary

#### Animation Design

**Expand Animation**
* Height expand + fade in
* Duration: **220ms**
* Curve: `ease-out`

**Save Animation**
* Text briefly highlights (subtle background tint)
* Highlight fades out over 300ms

**Edit Interaction**
* Tap quote → enters edit mode
* Cancel collapses back

#### After Saving (Read Mode)

```
"Everything he knew was suddenly uncertain."
```

* Quotation marks included
* Slight indent
* Italicized
* No box
* Looks like a literary excerpt

#### Quote Indicator in Word List

In the word list:
* A tiny quotation mark (❝) next to word
* Only if a quote exists
* No text, no labels

### 10.4 Data Model

```dart
class WordEntry {
  final String id;
  final String word;
  final String explanation;
  final String bookId;
  final DateTime timestamp;
  final int lookupCount;
  final DifficultyReason? difficultyReason;
  final String? quote; // optional

  bool get hasQuote => quote != null && quote!.trim().isNotEmpty;
}
```

No separate quote entity—stored with the word.

### 10.5 Database

#### Migration v2 → v3

**Location:** `lib/services/database/migrations.dart`

```dart
static Future<void> _migrateV2ToV3(Database db) async {
  await db.execute('''
    ALTER TABLE word_entries ADD COLUMN quote TEXT
  ''');
}
```

### 10.6 Copy Variants

Rotate sparingly:
* "Add the sentence it appeared in"
* "Remember the line it came from"
* "Save the sentence, if you'd like"

### 10.7 File Structure

```
lib/
├── models/
│   └── word_entry.dart           # MODIFIED (quote field)
├── widgets/
│   ├── quote_capture_section.dart # NEW
│   ├── word_explanation_sheet.dart # MODIFIED
│   └── word_list_item.dart        # MODIFIED (quote indicator)
└── services/
    └── database/
        ├── database_service.dart  # MODIFIED (version 3)
        └── migrations.dart        # MODIFIED (v3 migration)
```

### 10.8 Why This Feature Is Powerful

**Emotional Value**
* Readers remember *moments*, not definitions
* Seeing the sentence instantly revives the scene

**Literary Authenticity**
* Feels like underlining in a paperback
* Honors how people actually read

**Long-term Retention**
* Words learned with context stick longer
* Revisiting quotes is more rewarding than revisiting meanings

### 10.9 What This Feature Is NOT

❌ Not full quote highlighting
❌ Not chapter tracking
❌ Not page numbers
❌ Not copyright-heavy extraction
❌ Not forced

Everything is **user-remembered**, not scraped.

---

## 11. Dark Mode Refinement (v1.8.0)

### 11.1 Overview

A comprehensive dark mode polish that transforms the existing dark theme into a premium "paper-warm night reading" experience. This update focuses on reducing visual harshness, adding warmth, and creating the feel of reading under a warm lamp.

**Goals:**
- Reduce contrast harshness (no pure black/white)
- Warmer, paper-like text colors
- Softer dividers and borders
- Paper surface layering for depth
- Remove heavy shadows, use color layering instead
- Desaturated accent colors for night comfort
- Warm overlays for interaction states

### 11.2 Design Philosophy

> *"Like reading at night under a warm lamp. Old paper, ink absorbed into parchment, reduced eye strain."*

The refinement follows the principle that **premium apps don't shout** — they whisper. Instead of bold contrasts and heavy shadows, Contexta's dark mode now uses:

1. **Layered surfaces** instead of shadows for depth
2. **Warm tones** instead of cool grays
3. **Subtle borders** instead of drop shadows
4. **Desaturated accents** that don't strain eyes at night

### 11.3 Color System

#### Core Dark Palette

| Token | Hex | Purpose |
|-------|-----|---------|
| `darkBackground` | `#1E1B18` | Deep brown-black base |
| `darkBackgroundElevated` | `#252220` | Slightly lifted background |
| `darkPaper` | `#2A2622` | Card surfaces |
| `darkPaperElevated` | `#332E28` | Elevated cards, sheets |
| `darkPaperHighest` | `#3B3530` | Highest elevation (inputs) |

#### Text Colors

| Token | Hex | Purpose |
|-------|-----|---------|
| `darkTextPrimary` | `#EDE6D8` | Warm off-white for main text |
| `darkTextSecondary` | `#B5AD9E` | Muted taupe for secondary |
| `darkTextMuted` | `#8A847A` | Hints, timestamps, captions |

#### Border Colors

| Token | Hex | Purpose |
|-------|-----|---------|
| `darkBorder` | `#3D3832` | Standard dividers |
| `darkBorderSubtle` | `#332E28` | Very soft dividers |

#### Accent & Overlay

| Token | Value | Purpose |
|-------|-------|---------|
| `darkAccent` | `#6C7A9A` | Desaturated blue (was `#7B8AB5`) |
| `darkOverlay` | `rgba(237, 230, 216, 0.05)` | Warm hover state |
| `darkOverlayPressed` | `rgba(237, 230, 216, 0.08)` | Warm pressed state |

### 11.4 Shadow Strategy

**Before (v1.7.0):** Heavy black shadows on all cards, buttons, sheets

**After (v1.8.0):** Color layering + subtle borders

#### The Principle

In dark mode, shadows feel like "mud" — they don't lift elements, they just create visual noise. Instead, we use:

1. **Lighter surface colors** to show elevation
2. **Subtle border accents** for definition
3. **No BoxShadow** in dark mode

#### Implementation Pattern

```dart
// Before: Same shadow, just more opaque
boxShadow: [
  BoxShadow(
    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
    blurRadius: 8,
  ),
]

// After: No shadow in dark, layered surface instead
boxShadow: isDark
    ? [] // No shadow
    : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
border: isDark
    ? Border.all(color: AppTheme.darkBorderSubtle, width: 0.5)
    : null,
```

### 11.5 Helper Methods

New helper methods in `AppTheme` for consistent theming:

```dart
// Surface elevation helpers
static Color getPaperElevated(BuildContext context)
static Color getSurfaceHighest(BuildContext context)

// Border helpers
static Color getBorderSubtle(BuildContext context)

// Overlay helpers
static Color getOverlay(BuildContext context)
static Color getOverlayPressed(BuildContext context)

// Shadow helpers (returns empty list in dark mode)
static List<BoxShadow> getCardShadow(BuildContext context)
static List<BoxShadow> getSubtleShadow(BuildContext context)

// Divider helpers
static Widget buildGradientDivider(BuildContext context)
```

### 11.6 Updated Components

#### Cards (`book_card.dart`)
- Removed all BoxShadow in dark mode
- Stacked paper layers use same surface color
- Added subtle border for definition

#### Bottom Sheet (`contexta_bottom_sheet.dart`)
- Surface: `darkPaperElevated`
- Border: Subtle top/left/right border
- Shadow: Empty in dark mode

#### Dialog (`contexta_dialog.dart`)
- Surface: `darkPaperElevated`
- Border: `darkBorderSubtle` all around
- Shadow: Empty in dark mode

#### Word List Item (`word_list_item.dart`)
- Hover: Uses `AppTheme.getOverlay(context)`
- Pressed: Uses `AppTheme.getOverlayPressed(context)`
- Divider: 0.7 opacity in dark mode

#### Book Detail Input (`book_detail_screen.dart`)
- Input card: `darkPaperElevated`
- Border: `darkBorderSubtle`
- Shadow: Empty in dark mode

#### FAB (`library_screen.dart`)
- Reduced glow to single shadow
- Alpha: 0.2, blur: 8 (was much higher)

#### Global Search (`global_search.dart`)
- Search bar: No shadow in dark
- Results dropdown: `darkPaperElevated`, no shadow

#### Word Frequency Card (`word_frequency_card.dart`)
- Surface: `darkPaperElevated`
- Border: `darkBorderSubtle`
- Shadow: Empty in dark mode

#### Export Options (`export_options_sheet.dart`)
- Format cards: No shadow when selected in dark
- Export button: No shadow in dark

#### Text Field (`contexta_text_field.dart`)
- Focus shadow: Disabled in dark mode

#### Selectors
- `explanation_level_selector.dart`: No indicator shadow in dark
- `difficulty_reason_selector.dart`: No selected chip shadow in dark

### 11.7 Theme Configuration Changes

```dart
// Card Theme
cardTheme: CardThemeData(
  elevation: isDark ? 0 : 2,  // No elevation in dark
  shadowColor: isDark ? Colors.transparent : charcoal.withValues(alpha: 0.08),
),

// FAB Theme
floatingActionButtonTheme: FloatingActionButtonThemeData(
  elevation: isDark ? 2 : 6,  // Reduced elevation in dark
),

// Divider Theme
dividerTheme: DividerThemeData(
  color: (isDark ? darkBorder : border).withValues(alpha: isDark ? 0.7 : 1.0),
),
```

### 11.8 Testing Dark Mode

To verify the refinement:

1. **Color Temperature**: UI should feel warm, not cold
2. **Elevation**: Cards should feel layered by color, not shadow
3. **Contrast**: Text should be readable but not glaring
4. **Accent**: Blue should be muted, not vibrant
5. **Interactions**: Hover/press states should have warm overlay

### 11.9 What This Feature Is NOT

❌ Not a complete theme redesign
❌ Not new features
❌ Not changing light mode
❌ Not adding new colors to light mode
❌ Not performance-related

This is **polish** — making what exists feel premium.

---

## 12. Shelf Interaction (v1.9.0)

### 12.1 Overview

**"The shelf opens to receive a book."**

This feature transforms adding books from a utilitarian screen transition into a spatial, intentional ritual. The add-book flow is now anchored as a **persistent spatial element** (the shelf) that expands from the top of the library, revealing form content below it. When users place a book, it flies from the form up to the shelf with a settle animation, then appears in the library list.

**Goals:**
- Turn book addition from transaction into ritual
- Create spatial continuity (shelf is a place, not a screen)
- One signature animation that feels premium and restrained
- Differentiate Contexta through micro-interactions

### 12.2 Core Concept

#### The Shelf Is Spatial

The shelf is not a modal, route, or overlay. It is a **persistent conceptual element** at the top-left of the interface, always present in the user's mental model.

- When closed: Invisible, just an idea
- When open: Expands downward, revealing form content
- The form lives "underneath" the shelf

#### User Mental Model

> "I'm preparing a book at the shelf to place it in my library."

Not: "I'm filling out a form"
Not: "I'm navigating to add screen"
**Yes:** "The shelf opened to receive my book"

### 12.3 Animation System

#### Shelf Opening (220ms)

**Timing:** 220ms, `Curves.easeOutCubic`
**What moves:** Shelf expands downward from origin
**Content reveal:** 80ms delay, fades in (duration 140ms)
**Background:** Dims by 5-8% in parallel
**Feel:** Slow, confident, deliberate

```
0ms ─ Shelf begins expanding
80ms ─ Content begins fading in
220ms ─ Both animations complete
```

**Haptics:**
- FAB press: `lightImpact()`
- Shelf completion: Silent (the dim overlay is feedback)

#### Book Placement (480ms)

**Timing:** 480ms, `Curves.easeOutCubic` (deceleration at end)
**Start position:** Preview card location in the form
**End position:** Library list, top with slight offset
**Trajectory:** Slightly diagonal, with subtle arc (−20px peak at 50% progress)
**Scale:** Lift (1.02) → Travel (0.98) → Settle (1.0)
**Elevation:** Shadow follows book, peaks at 8px, settles at 2px

**Haptics:**
- Placement start: `lightImpact()`
- Book lands: `selectionClick()` (settle feel)

#### Shelf Closing (220ms)

**Timing:** 220ms, `Curves.easeOutCubic`
**What moves:** Shelf contracts upward
**What fades:** Content fades with shelf
**Background:** Dim overlay fades
**Trigger:** Automatic after book settles, or user taps dim overlay
**Feel:** Natural return to rest state

### 12.4 Components

#### ShelfController

Manages all shelf animation state:

```dart
class ShelfController extends ChangeNotifier {
  bool get isOpen;           // Shelf is expanded
  bool get isAnimating;      // Currently animating
  bool get isPlacingBook;    // Book in flight
  
  void open();               // Start opening
  void close();              // Start closing
  void startPlacingBook();   // Begin placement
  void finishPlacingBook();  // Book landed
  void onAnimationComplete();// Called by AnimationController
}
```

#### ShelfOverlay

Parent widget that wraps the library screen with shelf functionality:

**Responsibilities:**
- Manages all animation controllers (shelf expansion, book placement)
- Renders dim overlay when open
- Renders shelf content below library
- Renders flying book during placement
- Calculates book trajectory and position

**Key Properties:**
- `controller`: ShelfController for state management
- `addBookBuilder`: Widget builder for form content
- `child`: The library screen (books list, FAB, etc.)

#### AddBookPanel

The form that appears when shelf expands:

**Content:**
- Header: "Add a Book" with close button
- Title field (required) with real-time validation
- Author field (optional)
- Book preview card (appears as user types title)
- "Place on Shelf" button

**Real-time Preview:**
- Appears when title is not empty
- Fade + scale animation (200ms)
- Shows book card matching library style
- Displays: Title, Author, "0 words" stat
- North arrow icon hints at upward placement

**Preview Card Position:**
- GlobalKey cached to get exact position during flight
- Position used as start point for placement animation

### 12.5 User Journey

#### 1. Library View (Idle)

User sees book list, FAB visible. Everything is still.

#### 2. FAB Tap

- FAB scales down (0.95, 100ms) with haptic
- Shelf controller receives `open()` signal
- Background dims (5-8%)
- Shelf expands downward (220ms)
- Form content fades in (80ms delay, 140ms duration)

#### 3. User Enters Book Info

- Title field auto-focused
- Author field optional
- As user types title:
  - Preview card appears with fade + scale
  - Shows title, author, word count (0)
  - Updates in real-time

#### 4. Place on Shelf Tap

- Preview card fetches its position via GlobalKey
- Button disables during animation
- Book card scales up slightly (lift phase)
- Book travels from form to list (480ms)
  - Diagonal trajectory with subtle arc
  - Shadow follows elevation
  - Scale: 1.02 (lift) → 0.98 (travel) → 1.0 (settle)

#### 5. Book Lands

- Haptic feedback (settle click)
- Book appears in library list
- List auto-scrolls to show new book
- New book highlighted with soft glow (300ms)
- Shelf automatically closes (220ms)
- Background returns to normal
- List is now focused, ready for interaction

#### 6. Back to Library

User sees new book in the list, highlight fades. Continuity preserved — the book is already there.

### 12.6 Technical Details

#### Animation Architecture

All animations use **AnimationController** with **TickerProvider**:

```dart
// Shelf expansion
_shelfController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 220),
);

// Book placement
_bookPlacementController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 480),
);
```

#### Position Calculation

Book start position obtained from GlobalKey during build:

```dart
final RenderBox cardBox = 
  _previewCardKey.currentContext?.findRenderObject() as RenderBox;
final position = cardBox.localToGlobal(Offset.zero);
final size = cardBox.size;
```

End position calculated as library list top with padding:

```dart
final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
_bookEndPosition = Offset(16, appBarHeight + 16);
```

#### Arc Trajectory

Subtle upward arc at midpoint of flight:

```dart
final arcOffset = -20 * (1 - (2 * progress - 1) * (2 * progress - 1));
final currentY = baseY + arcOffset;
```

This creates a gentle curve without feeling bouncy.

#### Scale Phases

Three distinct scaling phases during flight:

1. **Lift (0-10%):** Scale 1.0 → 1.02 (user intent confirmed)
2. **Travel (10-90%):** Scale 1.02 → 0.98 (tightens for flight)
3. **Settle (90-100%):** Scale 0.98 → 1.0 (lands gently)

#### Highlight Animation

New book highlighted with TweenSequence:

```dart
TweenSequence<double>([
  TweenSequenceItem(tween: ConstantTween(0.0), weight: 36), // Delay
  TweenSequenceItem(tween: Tween(0.0 → 1.0), weight: 64),   // Fade in
  TweenSequenceItem(tween: Tween(1.0 → 0.0), weight: 40),   // Fade out
]).animate(_highlightController);
```

Total duration: 1200ms, creating a subtle glow that appears then fades.

### 12.7 Performance & Stability

**No Complex Rendering:**
- Standard compositing (no custom paint)
- Uses `Transform.scale`, `Opacity`, `Positioned`
- No physics engines or complex curves

**Hardware Acceleration:**
- GPU-accelerated transforms
- No JavaScript/Shader code
- 60fps on mid-range devices

**Memory:**
- Controllers disposed properly
- No leaks in animation callbacks
- StreamBuilder pattern avoided for simplicity

### 12.8 Failure Modes Avoided

✅ Shelf appears smoothly (not abrupt)
✅ Book travels (not teleports)
✅ No bounce or overshoot
✅ No loud sounds
✅ No long delays
✅ Motion feels inevitable (not playful)

The entire experience should feel **premium, intentional, and restrained**.

### 12.9 What This Feature Is NOT

❌ Not drag-and-drop
❌ Not physics-based animation
❌ Not customizable animations
❌ Not modal-based (shelf is spatial, not modal)
❌ Not adding book validation (existing validation stays)

This is **ritual** — turning transaction into moment.

---

## 13. Gentle Suggestions (v1.10.0)

*Commit: `feat: Add gentle author and word spelling suggestions`*

### 13.1 Overview

Contexta now provides **gentle suggestions** for author names and word spellings. The philosophy is assistance that whispers, never shouts — like a pencil correcting spelling in the margin, not Google shouting results at you.

### 13.2 Core Principle

Contexta should **assist silently**, not interrupt.

Suggestions feel like:
- ✅ A pencil correcting spelling in the margin
- ❌ NOT Google shouting results at you

**Key Guidelines:**
- Max 3 suggestions at a time
- No dropdown covering the screen
- No red error indicators
- No aggressive autocomplete
- Disappear when not needed

---

### 13.3 Author Name Suggestions

#### Why This Makes Sense

Readers often:
- Misspell names (Dostoyevsky vs Dostoevsky)
- Partially remember authors
- Use initials or surnames

Clean author names improve:
- Context quality later (AI explanations)
- Visual polish in library
- Data consistency

#### UX Behavior

**Trigger:** After **2+ characters** typed in Author field

**Display:** Small suggestion strip appears *below* the field

**Max Suggestions:** 3

**Example:**

```
George Or…
────────────
George Orwell
George Eliot
George Bernard Shaw
```

**Selection:**
- Tap suggestion → fills author field
- Suggestions disappear immediately
- Cursor moves to end
- No confirmation message

It should feel *invisible when correct*.

#### Suggestion Sources (Prioritized)

1. **Previously used authors** (learns from user)
2. **Curated literary authors** (500+ classic authors)

No API calls needed — fully offline.

---

### 13.4 Word Spelling Suggestions

#### Why This Is Critical

Readers often:
- Misspell unfamiliar words
- Type phonetically
- Get rejected by API or dictionary

A spelling suggestion saves frustration.

#### UX Behavior

**Trigger:** 
- User pauses for **400ms** after typing
- NOT while typing fast

**Display:** Soft inline suggestion below word input

```
Did you mean ineffable?
```

- Italic text
- Muted color
- Only the suggested word is clickable

**Acceptance:**
- Tap suggested word
- Input updates
- Explanation proceeds automatically

**No red errors. No blocking dialogs.**

Feels like a gentle correction, not a warning.

---

### 13.5 Services

#### AuthorSuggestionService

**Location:** `lib/services/author_suggestion_service.dart`

```dart
class AuthorSuggestionService {
  /// Get suggestions for author name
  /// Returns max 3 suggestions, prioritizing previously used authors
  Future<List<String>> getSuggestions(String query);
  
  /// Record an author as used (for future prioritization)
  Future<void> recordAuthor(String author);
}
```

**Curated Authors:** 130+ literary authors including:
- Classic Literature (Dostoevsky, Austen, Dickens, Tolstoy)
- American Literature (Hemingway, Faulkner, Morrison)
- British Modern (Orwell, Huxley, Ishiguro)
- World Literature (García Márquez, Borges, Murakami)
- Philosophy (Nietzsche, Kierkegaard, Arendt)
- Poetry (Eliot, Dickinson, Rilke)
- Contemporary (Atwood, Ferrante, Rooney)

#### SpellingSuggestionService

**Location:** `lib/services/spelling_suggestion_service.dart`

```dart
class SpellingSuggestionService {
  /// Get spelling suggestion for a potentially misspelled word
  /// Returns null if word appears correct or no close match found
  String? getSuggestion(String word);
}
```

**Algorithm:** Levenshtein distance with dynamic threshold:
- Short words (3-4 chars): max 1 edit
- Medium words (5-8 chars): max 2 edits
- Long words (9+ chars): max 3-4 edits

**Word List:** 500+ challenging vocabulary words commonly looked up in literature.

---

### 13.6 UI Components

#### SuggestionStrip

**Location:** `lib/widgets/suggestion_strip.dart`

A gentle suggestion strip that appears below input fields.

```dart
SuggestionStrip(
  suggestions: ['George Orwell', 'George Eliot', 'George Bernard Shaw'],
  onSelect: (author) => _handleAuthorSelect(author),
  isVisible: true,
)
```

**Visual Style:**
- Same background as paper cards
- Rounded corners (12px)
- Thin divider between items
- Serif text for names
- Muted until hovered/tapped

**Animation:**
- Fade + slight slide up
- Duration: 150ms
- Curve: easeOut
- Disappears instantly on selection

#### SpellingSuggestion

**Location:** `lib/widgets/spelling_suggestion.dart`

A gentle inline spelling suggestion widget.

```dart
SpellingSuggestion(
  suggestion: 'ineffable',
  onAccept: () => _acceptSuggestion(),
  isVisible: !_isLoading,
)
```

**Displays as:**

*Did you mean **ineffable**?*

- Italic text for "Did you mean"
- Bold/clickable for suggestion
- Subtle color (ink blue)
- Underline on hover

---

### 13.7 Animation & Micro-interactions

#### Suggestion Appearance
- **Animation:** Fade + slight slide up
- **Duration:** 150ms
- **Curve:** easeOut
- **No bounce** (maintains literary dignity)

#### Disappearance
- **Fade out instantly** on selection
- **No lingering UI**

#### Haptic Feedback
- `HapticFeedback.selectionClick()` on selection

---

### 13.8 Copy Tone Guidelines

#### ✅ Correct Tone
- "Did you mean…"
- "Possible match"
- "Closest word"

#### ❌ Wrong Tone
- "Incorrect spelling"
- "Error"
- "No results found"
- "Invalid input"

**Contexta must never shame the reader.**

---

### 13.9 When Suggestions Stay Silent

Do **not** suggest if:
- User deliberately typed a variant
- Word exists but is rare
- Author is uncommon but valid
- Input is too short (< 2 chars for author, < 3 chars for word)

**False confidence damages trust.**

---

### 13.10 Integration Points

#### AddBookPanel

```dart
// Author field with suggestions
ContextaTextField(
  label: 'Author (optional)',
  value: _author,
  onChanged: _handleAuthorChange,
),
SuggestionStrip(
  suggestions: _authorSuggestions,
  onSelect: _handleAuthorSuggestionSelect,
  isVisible: _showAuthorSuggestions,
),
```

#### BookDetailScreen

```dart
// Word input with spelling suggestion
ContextaTextField(
  placeholder: 'Enter a word you paused at',
  value: _wordController.text,
  onChanged: _handleWordChange,
),
SpellingSuggestion(
  suggestion: _spellingSuggestion,
  onAccept: _acceptSpellingSuggestion,
  isVisible: !_isLoading,
),
```

---

### 13.11 Why This Feature Adds Value Without Complexity

- ✅ Reduces friction
- ✅ Improves data quality
- ✅ Helps AI later
- ✅ Makes app feel intelligent
- ✅ Zero visual clutter if done right

Most importantly:

> It disappears when not needed

---

### 13.12 How This Fits Contexta's Identity

This is not "search".
This is **assistance**.

The app feels like:
- A careful reader sitting beside you
- Occasionally whispering a correction
- Never interrupting your flow

---

## 14. Book Suggestions (v1.11.0)

### 14.1 Overview

Help readers **discover what to read next** without pushing recommendations, demanding preferences, or breaking Contexta's calm, bookish tone.

The feature feels **earned, optional, and respectful**.

---

### 14.2 Core Philosophy

**Non-Negotiable UX Principles:**

| Principle | Implementation |
|-----------|----------------|
| User-initiated only | Never auto-show suggestions |
| Explain absence clearly | No empty or confusing states |
| Few, thoughtful suggestions | Max 3 at a time |
| Always explain "why" | Trust > accuracy |
| No premature personalization | Wait for reading history |

**The Librarian Metaphor:**

Contexta sounds like a **quiet librarian**, not an algorithm:

| ✅ Use | ❌ Avoid |
|--------|----------|
| "You might enjoy…" | "Recommended for you" |
| "Often read after…" | "Top picks" |
| "Similar in tone to…" | "Trending" |
| "Based on your reading…" | "AI-powered" |

---

### 14.3 Entry Point

**Location:** App Bar (top-right)

**Icon:** Open book (`Icons.auto_stories_outlined`)
- Same visual priority as settings icon
- No "AI" badge, sparkles, or glow
- Neutral, bookish, calm

**Tooltip:** "Reading suggestions"

```dart
// Library screen app bar
ContextaAppBar(
  title: 'My Shelf',
  rightAction: Row(
    children: [
      _SuggestionsButton(onTap: _showBookSuggestions),
      _SettingsButton(onTap: _showSettings),
    ],
  ),
)
```

---

### 14.4 Empty Shelf State

**Purpose:** Explain why suggestions don't exist yet. Invite, don't pressure.

**Visual Design:**

```
┌─────────────────────────────────────┐
│                                     │
│          [📚 Icon in circle]        │
│                                     │
│  "Every reading journey starts      │
│   somewhere."                       │
│        (italic, muted)              │
│                                     │
│  "Add your first book to Contexta,  │
│   and this space will begin         │
│   offering thoughtful suggestions   │
│   shaped by how you read."          │
│        (body, muted)                │
│                                     │
│    [ Add your first book ]          │
│        (primary button)             │
│                                     │
│  ─────────────────────────          │
│                                     │
│  Often chosen as a starting point   │
│        (label, subtle)              │
│                                     │
│  ▌ To Kill a Mockingbird — Lee      │
│    A timeless exploration...        │
│                                     │
│  ▌ Pride and Prejudice — Austen     │
│    A witty examination...           │
│                                     │
│  ▌ 1984 — Orwell                    │
│    A profound meditation...         │
│                                     │
└─────────────────────────────────────┘
```

**Timeless Classics:**

```dart
class TimelessSuggestions {
  static const List<BookSuggestion> classics = [
    BookSuggestion(
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      reason: 'A timeless exploration of justice and moral growth.',
    ),
    BookSuggestion(
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      reason: 'A witty examination of society and human nature.',
    ),
    BookSuggestion(
      title: '1984',
      author: 'George Orwell',
      reason: 'A profound meditation on power and truth.',
    ),
  ];
}
```

---

### 14.5 Suggestions State

**Purpose:** Offer gentle guidance based on reading history.

**Data Used (UX-level):**
- Books on shelf
- Authors read
- Words saved (tone/difficulty)
- Reading frequency (light signal)

No explicit preferences. No questionnaires.

**Visual Design:**

```
┌─────────────────────────────────────┐
│                                     │
│  📚 Reading Suggestions      🔄     │
│                                     │
│  "Based on your reading…"           │
│        (header, italic, muted)      │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ The Trial — Franz Kafka     │    │
│  │ Explores moral uncertainty, │    │
│  │ similar to themes in your   │    │
│  │ recent reading.             │    │
│  │                             │    │
│  │  [+ Add to Shelf] [Dismiss] │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Norwegian Wood — Murakami   │    │
│  │ Often read after exploring  │    │
│  │ Dostoevsky's emotional      │    │
│  │ landscapes.                 │    │
│  │                             │    │
│  │  [+ Add to Shelf] [Dismiss] │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Stoner — John Williams      │    │
│  │ You might enjoy its quiet   │    │
│  │ examination of a literary   │    │
│  │ life.                       │    │
│  │                             │    │
│  │  [+ Add to Shelf] [Dismiss] │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**Actions Per Suggestion:**

| Action | Behavior |
|--------|----------|
| Add to Shelf | Adds book, removes card, closes if last |
| Dismiss | Removes card, closes if last |

No like/dislike. No feedback prompts.

---

### 14.6 Services

#### BookSuggestionService

```dart
class BookSuggestionService {
  /// Get personalized suggestions
  Future<BookSuggestionsResult> getSuggestions({
    required List<Book> books,
    bool forceRefresh = false,
  });

  /// Clear cached suggestions
  Future<void> clearCache();
}
```

**Features:**
- 24-hour cache with library hash
- Filters out books already on shelf
- Connectivity-aware (cached when offline)
- Max 3 suggestions per request

**AI Prompt Design:**

```
You are a thoughtful librarian helping a reader discover their next book.

RULES:
1. Never suggest books already in their library
2. Each suggestion must include a clear, personal reason
3. Use phrases like "You might enjoy...", "Similar in tone to..."
4. Never use "recommended", "top pick", "trending"
5. Keep reasons to one thoughtful sentence
```

#### BookSuggestion Model

```dart
class BookSuggestion {
  final String title;
  final String author;
  final String reason;
  final String? coverUrl;
  
  /// Check if matches a shelf book
  bool matchesBook(String bookTitle, String bookAuthor);
}
```

---

### 14.7 UI Components

#### BookSuggestionsSheet

Main orchestrator that switches between states:

```dart
BookSuggestionsSheet(
  books: widget.books,
  onAddBook: (title, author) { ... },
  onClose: () => Navigator.pop(),
  onNavigateToAddBook: () => _shelfController.open(),
)
```

#### EmptyShelfSuggestions

Calm explanation with optional timeless suggestions:

```dart
EmptyShelfSuggestions(
  onAddBook: _handleAddFirstBook,
  showTimelessSuggestions: true,
)
```

#### SuggestionsList

Displays max 3 suggestions with staggered fade-in:

```dart
SuggestionsList(
  suggestions: _suggestions,
  onAddToShelf: _handleAddToShelf,
  onDismiss: _handleDismiss,
  isLoading: _isLoading,
  error: _error,
  onRetry: _loadSuggestions,
)
```

---

### 14.8 Animation & Timing

**Bottom Sheet:**
- Slide up: 200ms
- Content fade: 200ms
- No staggered list in empty state

**Suggestions List:**
- Staggered fade-in: 70ms gap between cards
- Each card: 200ms fade with easeOut
- Feels like "ideas surfacing"

**Refresh Button:**
- 500ms rotation animation on tap
- Subtle, not attention-seeking

**Exit Behavior:**
- Swipe down or tap outside to close
- No "Are you sure?" prompts
- Closing = "Not now" (respected)

---

### 14.9 Copy Tone Guidelines

**Header Text:**

```dart
// Empty state
"Every reading journey starts somewhere."  // italic, muted

// Has books
"Based on your reading…"  // italic, muted
```

**Body Text:**

```dart
"Add your first book to Contexta, and this space will begin 
offering thoughtful suggestions shaped by how you read."
```

**Labels:**

```dart
"Often chosen as a starting point"  // for timeless classics
"Finding thoughtful suggestions…"   // loading state
```

**Reason Examples:**

```dart
"Explores moral uncertainty, similar to themes in your recent reading."
"Often read after exploring Dostoevsky's emotional landscapes."
"You might enjoy its quiet examination of a literary life."
```

---

### 14.10 Refresh Logic

Suggestions refresh **only when**:
1. User explicitly taps refresh icon
2. OR a new book is added to shelf

**Never:**
- Auto-refresh
- Show "new suggestions" badges
- Push notifications

---

### 14.11 Success Criteria

You've built it right if:

✅ Users don't notice it until they need it
✅ No one asks "why am I seeing this?"
✅ Users feel understood, not targeted
✅ The feature feels calm, not exciting

> Excitement is short-lived.  
> Trust lasts.

---

### 14.12 Project Structure (New Files)

```
lib/
├── models/
│   └── book_suggestion.dart       # Suggestion model + timeless classics
├── services/
│   └── book_suggestion_service.dart  # AI-powered suggestions
└── widgets/
    ├── book_suggestions_sheet.dart   # Main orchestrator
    ├── empty_shelf_suggestions.dart  # Empty state UI
    └── suggestions_list.dart         # Suggestions with animations
```

---

## 15. API Reference

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

## 16. Project Architecture

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

## 17. Troubleshooting

### Common Issues

#### Export Share Not Working on Emulator
**Symptoms:** Tapping share button does nothing, no share dialog appears

**Cause:** Android Emulator may not have apps registered to handle share intents.

**Solutions:**
1. **Test on real device** - Share works correctly on physical Android/iOS devices
2. **Install sharing apps** - Install Gmail, Drive, or another app that handles file sharing
3. **Check logs** - Look for `ExportService: Opening share dialog...` in console
4. **Verify file creation** - Check for `ExportService: PDF written` or `Text content written`

**Debug Output:**
```
ExportService: Starting export with format PDF Document
ExportService: Exporting 8 words
ExportService: Generated filename: 1984_words_2026-01-30.pdf
ExportService: File path: /data/.../1984_words_2026-01-30.pdf
ExportService: Generating PDF...
ExportService: PDF written (12345 bytes)
ExportService: Opening share dialog...
ExportService: Share completed with status: ShareResultStatus.success
```

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
ExportService: Starting export with format PDF Document
ExportService: Share completed with status: ShareResultStatus.success
```

---

## 12. Known Issues & Security Considerations

### Known Issues

| Issue | Severity | Status | Workaround |
|-------|----------|--------|------------|
| Share may not work on emulators | Low | By Design | Test on real device |
| Large exports (1000+ words) may be slow | Low | Open | Paginate or limit export |
| ID collision possible in same millisecond | Low | Open | Very unlikely in practice |

### Security Considerations

#### API Key Handling
- ✅ API key stored in `.env` file (not committed to git)
- ✅ `.env.example` provides template without sensitive data
- ✅ Fallback message when API key is missing
- ⚠️ API key is sent to Perplexity API (required for functionality)

#### Data Storage
- ✅ SQLite database stored in app's private directory
- ✅ SharedPreferences for non-sensitive settings
- ✅ No user data sent to external servers (except word explanations)
- ✅ Export files written to temporary directory

#### Input Handling
- ✅ JSON encoding for API requests (prevents injection)
- ✅ Filename sanitization for exports (removes special characters)
- ⚠️ User input used directly in AI prompts (by design for context)

### Memory Management

#### Services Lifecycle
```dart
// In _ContextaAppState.dispose()
@override
void dispose() {
  ConnectivityService().dispose();  // Cleans up StreamController
  super.dispose();
}
```

#### Resource Cleanup
- ✅ ConnectivityService disposes StreamController and subscription
- ✅ Animation controllers disposed in widget dispose methods
- ✅ HTTP clients created per-request in singleton services

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

## 18. Changelog

All notable changes to Contexta are documented here.

### [1.11.0] - 2026-01-31

#### Feature - Gentle Book Suggestions
*Commit: feat: Add gentle book suggestions feature*

- **BookSuggestionService**
  - AI-powered suggestions using Perplexity API
  - 24-hour cache with library hash
  - Max 3 thoughtful suggestions
  - Filters out books already on shelf
  - Connectivity-aware caching

- **BookSuggestion Model**
  - Title, author, reason fields
  - Timeless classics for empty shelf
  - Duplicate detection logic

- **BookSuggestionsSheet**
  - Main orchestrator widget
  - Empty shelf state with explanation
  - Personalized suggestions state
  - Refresh button with rotation animation

- **EmptyShelfSuggestions Widget**
  - Calm explanation of absence
  - "Add your first book" CTA
  - Optional timeless classics section
  - Fade-in animation

- **SuggestionsList Widget**
  - Staggered fade-in (70ms gap)
  - Add to Shelf / Dismiss actions
  - Loading and error states
  - Retry capability

- **App Bar Integration**
  - Open book icon in top-right
  - Tooltip: "Reading suggestions"
  - Same priority as settings icon

---

### [1.10.0] - 2026-01-31

#### Feature - Gentle Suggestions (Author & Word)
*Commit: feat: Add gentle author and word spelling suggestions*

- **AuthorSuggestionService**
  - Curated list of 130+ literary authors
  - Previously used authors prioritized
  - Fuzzy matching by word start
  - Persisted via SharedPreferences
  - Max 3 suggestions returned

- **SpellingSuggestionService**
  - 500+ challenging vocabulary words
  - Levenshtein distance algorithm
  - Dynamic edit distance threshold
  - Returns single best match or null

- **SuggestionStrip Widget**
  - Appears below author input field
  - Triggers after 2+ characters
  - Max 3 suggestions displayed
  - Fade + slide up animation (150ms)
  - Literary styling (serif, muted colors)
  - Disappears instantly on selection

- **SpellingSuggestion Widget**
  - Inline "Did you mean X?" format
  - Triggers after 400ms pause
  - Italic text, clickable word only
  - Auto-proceeds with explanation on tap
  - Never shames the reader

- **AddBookPanel Integration**
  - Author suggestions below author field
  - Records used authors for learning
  - Haptic feedback on selection

- **BookDetailScreen Integration**
  - Spelling suggestion below word input
  - Debounced 400ms after typing stops
  - Clears on explanation start
  - Auto-explain on suggestion accept

- **Design Philosophy**
  - Assist silently, never interrupt
  - Feels like pencil in margin
  - No dropdown spam
  - No red error indicators
  - Disappears when not needed

---

### [1.9.0] - 2026-01-30

#### Feature - Shelf Interaction (Book Addition Ritual)
*Commit: feat: Add shelf animation for premium book placement ritual*

- **ShelfController**
  - State management for shelf open/close/placing states
  - Extends ChangeNotifier for reactive updates
  - Handles animation completion callbacks

- **ShelfOverlay Widget**
  - Parent wrapper for library screen
  - Manages shelf expansion animation (220ms)
  - Manages book placement animation (480ms)
  - Renders dim overlay (5-8% alpha)
  - Renders flying book during placement
  - Position calculation using GlobalKey

- **AddBookPanel Widget**
  - New form panel that appears when shelf expands
  - Real-time book preview card with fade/scale animation
  - Title (required) and Author (optional) fields
  - "Place on Shelf" button
  - Auto-scroll to book after placement

- **Animation Details**
  - Shelf opening: 220ms easeOutCubic (content fades 80ms delayed)
  - Book placement: 480ms easeOutCubic with:
    - Lift phase (1.0 → 1.02)
    - Travel phase (1.02 → 0.98) with subtle arc
    - Settle phase (0.98 → 1.0)
  - Shelf closing: 220ms easeOutCubic
  - New book highlight: 1200ms glow (appear, hold, fade)

- **Haptic Feedback**
  - FAB press: `lightImpact()`
  - Book placement intent: `lightImpact()`
  - Book lands: `selectionClick()`

- **UX Enhancements**
  - No route transition (spatial overlay)
  - Auto-scroll to new book
  - Soft highlight on newly added book
  - Dim overlay closes shelf when tapped
  - Empty state button also opens shelf

- **Architecture**
  - Removed AddBookScreen route navigation
  - Integrated shelf expansion as persistent spatial element
  - Library screen now manages all shelf state
  - Position-independent animation (works on all screen sizes)

---

### [1.8.0] - 2026-01-30

#### Polish - Dark Mode Refinement
*Commit: polish: Refine dark mode for premium night reading*

- **Color System Update**
  - Added `darkBackgroundElevated` (#252220) for lifted backgrounds
  - Added `darkPaperHighest` (#3B3530) for highest elevation
  - Added `darkBorderSubtle` (#332E28) for very soft dividers
  - Added `darkOverlayPressed` for warm pressed states
  - Desaturated accent color (#7B8AB5 → #6C7A9A)

- **Shadow Strategy**
  - Removed all BoxShadow in dark mode across widgets
  - Use color layering instead of shadows for depth
  - Added subtle borders for card definition
  - Reduced FAB glow intensity

- **New Theme Helpers**
  - `getPaperElevated()` - elevated surface color
  - `getSurfaceHighest()` - highest elevation color
  - `getBorderSubtle()` - very soft border color
  - `getOverlay()` / `getOverlayPressed()` - warm interaction overlays
  - `getCardShadow()` / `getSubtleShadow()` - smart shadow helpers
  - `buildGradientDivider()` - fade-in/out divider widget

- **Updated Components**
  - BookCard: No shadow, subtle border
  - BottomSheet: darkPaperElevated, border instead of shadow
  - Dialog: darkPaperElevated, border instead of shadow
  - WordListItem: Warm overlays for interactions
  - BookDetailScreen: Input card uses elevated surface
  - GlobalSearch: No shadows, elevated surfaces
  - WordFrequencyCard: No shadow, subtle border
  - ExportOptionsSheet: No shadows in dark
  - TextField: No focus shadow in dark
  - Selectors: No indicator shadows in dark

- **Philosophy**
  - "Like reading under a warm lamp"
  - Premium apps whisper, they don't shout
  - Layered surfaces instead of heavy shadows
  - Warm tones instead of cool grays

---

### [1.7.0] - 2026-01-30

#### Added - Quote Capture (Sentence in Context)
*Commit: feat: Add quote capture for contextual word memory*

- **QuoteCaptureSection Widget**
  - Collapsible quote input with literary styling
  - Serif italic typography, muted colors
  - Expand animation (220ms, ease-out)
  - Save highlight animation (300ms fade)
  - Edit mode for existing quotes

- **WordEntry Model Update**
  - Added optional `quote` field
  - Added `hasQuote` getter
  - Updated copyWith, toJson, fromJson

- **WordListItem Enhancement**
  - Subtle quote indicator (❝) next to word
  - Only visible when quote exists
  - No labels, just visual cue

- **WordExplanationSheet Integration**
  - Quote section below explanation
  - Above book reference
  - One-tap to add, one-tap to edit

- **Database Migration v3**
  - Added quote column to word_entries table
  - Backward compatible (existing entries have NULL)

- **Philosophy**
  - Words remembered in context stick longer
  - Feels like underlining in a paperback
  - User-remembered, not scraped
  - Optional and invisible unless used

---

### [1.6.0] - 2026-01-30

#### Added - Reading Streak (Subtle Consistency Indicator)
*Commit: feat: Add reading streak feature for continuity tracking*

- **ReadingStreakService**
  - Singleton service for streak data management
  - Records unique reading days (one word = one day)
  - Calculates current streak and total active days
  - Stream-based updates for reactive UI
  - Light haptic feedback on new day

- **ReadingStreakIndicator Widget**
  - Subtle serif text display
  - Entry animation (fade + slide, 300ms)
  - Increment animation (dim effect, 200ms)
  - Mini dot row showing last 7 days
  - Copy variant rotation for variety

- **Settings System**
  - New SettingsSheet bottom sheet (StatefulWidget)
  - Theme mode toggle (light/dark)
  - "Show reading consistency" toggle
  - Export all words action
  - Persisted via SharedPreferences
  - Accessible from library app bar

- **UI Consolidation**
  - Moved theme toggle from app bar to settings
  - Moved export all button from app bar to settings
  - Cleaner app bar with single settings button
  - Immediate toggle feedback with local state

- **Database Migration v2**
  - New `reading_days` table
  - Unique date constraint (yyyy-MM-dd)
  - Index for fast date lookups

- **UI Integration**
  - Settings button in library app bar
  - Streak indicator below "My Books" header
  - Respects user toggle preference

- **Philosophy**
  - Not a habit tracker
  - Affirms continuity without pressure
  - Rewards presence, not frequency
  - Aligns with real reading patterns

---

### [1.5.1] - 2026-01-30

#### Fixed - Bug Fixes & Improvements
*Commit: fix: Critical bug fixes and improvements*

- **Filename Truncation Bug**
  - Fixed: Substring was using original length instead of sanitized length
  - Now properly limits to 30 characters after sanitization
  - Added trimming of leading/trailing underscores

- **Memory Leak Prevention**
  - Added `dispose()` to `_ContextaAppState` to clean up `ConnectivityService`
  - Proper cleanup of StreamController and subscriptions

- **Export Debugging**
  - Added comprehensive debug logging throughout export process
  - Logs file creation, byte sizes, and share status
  - Helps diagnose issues on emulators

- **UI Improvements**
  - Reduced format option padding for 3-column layout (12x8 instead of 16x12)
  - Smaller icons and text for better fit
  - Centered text alignment in format cards

---

### [1.5.0] - 2026-01-30

#### Added - Export Words
*Commit: feat: Add export functionality for vocabulary sharing*

- **ExportService**
  - Singleton service for content generation
  - Plain text format with ASCII styling
  - Markdown format with rich formatting
  - PDF format with professional layout
  - File generation with sanitized filenames
  - Native share via share_plus

- **PDF Generation**
  - Cover page for multi-book exports
  - Book headers with title and author
  - Styled word cards with backgrounds
  - Page numbers in footer
  - Multi-page support with pagination
  - Uses dart_pdf package

- **ExportOptionsSheet Widget**
  - Bottom sheet for format selection
  - Three format options: Plain Text, Markdown, PDF
  - Preview toggle with expand animation
  - Loading state with animated dots
  - Success/error snackbar feedback
  - Haptic feedback on interactions

- **ExportFormat Enum**
  - Plain Text (.txt) for universal compatibility
  - Markdown (.md) for notes apps like Obsidian, Notion
  - PDF (.pdf) for professional archival
  - Proper MIME types for sharing

- **BookDetailScreen Integration**
  - Export button in collection header
  - Per-book export with format choice
  - iOS-style share icon design

- **LibraryScreen Integration**
  - Export all button in app bar
  - Appears only when books have words
  - Full library export capability

- **Dependencies**
  - Added share_plus ^10.1.4
  - Added path_provider ^2.1.5
  - Added pdf ^3.11.3

---

### [1.4.0] - 2026-01-30

#### Added - Global Search Across Books
*Commit: feat: Add global word search across all books*

- **GlobalSearchBar Widget**
  - Bookmark-style ribbon animation on focus
  - Expand/collapse with smooth transitions (350ms)
  - Search input with placeholder "Search words"
  - Close button to collapse search
  - Results dropdown with fade + slide animation

- **SearchResult Model**
  - Links WordEntry to parent Book
  - Enables cross-book search results

- **_SearchResultItem Widget**
  - Bookmark-style left ribbon indicator
  - Word with query highlighting
  - Book title context display
  - Difficulty badge (if tagged)
  - Tap feedback animation

- **_HighlightedWord Widget**
  - Highlights matching substring in primary color
  - Background tint for visibility

- **LibraryScreen Integration**
  - Search bar appears when books have words
  - Result tap navigates to book and shows word
  - Deferred word sheet display pattern

- **Search Logic**
  - Case-insensitive substring matching
  - Exact matches prioritized
  - Secondary sort by recency
  - Maximum 10 results

- **WordEntry Bug Fix**
  - Handle legacy int storage for difficultyReason
  - Backward compatible JSON parsing

---

### [1.3.0] - 2026-01-30

#### Added - Difficulty Reason Tags
*Commit: feat: Add optional difficulty reason tagging*

- **DifficultyReason Enum**
  - `meaningUnclear`: Word meaning was unclear (blue icon)
  - `contextConfusing`: Context made it hard to understand (orange icon)
  - `philosophicalUsage`: Deep/philosophical usage (purple icon)
  - `archaicUsage`: Old or archaic language (teal icon)
  - Each reason has: label, description, icon, color
  - Storage-safe serialization methods

- **DifficultyReasonSelector Widget**
  - Poppy elastic entrance animation (staggered per chip)
  - Bounce feedback on selection
  - Subtle header "Why was this tricky?"
  - Optional skip button for skippable selection
  - Horizontal wrap layout for all screen sizes

- **DifficultyReasonBadge Widget**
  - Compact mode (icon only) for list items
  - Full mode (icon + label) for detail views
  - Theme-adaptive colors

- **WordExplanationSheet Updates**
  - Display difficulty badge for tagged words
  - "Add difficulty note" button for untagged words
  - Inline editing of difficulty reason
  - Auto-save when closing reason editor

- **WordListItem Updates**
  - Compact difficulty badge next to word title
  - Non-intrusive visual indicator

- **WordEntry Model Updates**
  - Optional `difficultyReason` field
  - `clearDifficultyReason` flag in copyWith()
  - Backward-compatible JSON serialization

---

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
│   ├── author_suggestion_service.dart   # Author suggestions (v1.10.0)
│   ├── spelling_suggestion_service.dart # Word spelling (v1.10.0)
│   └── word_explanation_cache_service.dart  # LRU cache (v1.1.0)
├── theme/
│   └── app_theme.dart                # Design tokens, colors
└── widgets/
    ├── add_book_panel.dart           # Shelf book form (v1.9.0)
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
    ├── shelf_overlay.dart            # Shelf animation (v1.9.0)
    ├── spelling_suggestion.dart      # Word spelling hint (v1.10.0)
    ├── suggestion_strip.dart         # Author suggestions (v1.10.0)
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

*This documentation covers Contexta from initial release through v1.10.0. For the latest updates, refer to the git commit history.*

*Last updated: January 31, 2026*
