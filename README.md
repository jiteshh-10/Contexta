# Contexta

<p align="center">
  <img src="assets/app_icon.png" alt="Contexta Logo" width="120" height="120">
</p>

<p align="center">
  <strong>A minimalist reading companion for curious minds</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#build">Build</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#design-system">Design System</a>
</p>

---

## Overview

**Contexta** is a thoughtful, minimalist Flutter application designed for readers who encounter unfamiliar words while reading physical or digital books. Unlike traditional dictionary apps, Contexta provides **contextual explanations** — understanding words within the literary context of the book you're reading.

### The Problem

When reading challenging literature, encountering an unfamiliar word breaks the flow. Traditional dictionaries provide generic definitions that often miss the nuanced meaning the author intended.

### The Solution

Contexta leverages AI (Perplexity API) to explain words in the context of your current book, providing:
- A **short definition** (4-5 words)
- A **contextual explanation** considering the book's themes, genre, and author's style

---

## Features

### 📚 Personal Library
- Add books you're currently reading with title and author
- Visual book cards with subtle animations
- Persistent storage across app sessions
- Empty state with branded illustration

### 🔍 Contextual Word Explanations
- Enter any word you encounter while reading
- AI-powered explanations using Perplexity API
- Explanations tailored to your book's context
- Short definition + detailed contextual meaning

### 📝 Word Collection
- Save explained words to each book
- View your vocabulary collection per book
- Edit words and refetch explanations
- Remove words with haptic feedback

### 🌓 Dark Mode
- Automatic system theme detection
- Manual toggle between light and dark
- Carefully crafted color palettes for both modes
- Reduced eye strain for nighttime reading

### ✨ Micro-interactions
- Smooth fade-in animations (700ms)
- Button press scaling (0.97x)
- Loading dots animation
- Haptic feedback on destructive actions

---

## Screenshots

| Splash Screen | Library (Empty) | Library (Books) |
|:-------------:|:---------------:|:---------------:|
| Branded logo animation | Encouraging empty state | Book cards grid |

| Book Detail | Word Explanation | Dark Mode |
|:-----------:|:----------------:|:---------:|
| Word input + collection | Contextual meaning | Full dark theme |

---

## Installation

### Prerequisites
- Flutter SDK ^3.7.2
- Dart SDK ^3.7.2
- Android Studio / VS Code
- Perplexity API key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/contexta.git
   cd contexta
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API key**
   
   Create a `.env` file in the project root:
   ```env
   # Perplexity API Configuration
   # Get your API key from: https://www.perplexity.ai/settings/api
   PERPLEXITY_API_KEY=your_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## Build

### Android APK

```bash
# Build release APK (all ABIs)
flutter build apk --release

# Build split APKs (smaller size per architecture)
flutter build apk --release --split-per-abi
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### App Icons

To regenerate app icons after modifying the source:

```bash
# Generate icon source files
dart run tool/generate_app_icon.dart

# Apply to all platforms
dart run flutter_launcher_icons
```

---

## Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point, state management
├── config/
│   └── api_config.dart       # API configuration (keys, endpoints)
├── models/
│   ├── book.dart             # Book data model
│   └── word_entry.dart       # Word entry data model
├── screens/
│   ├── splash_screen.dart    # Animated splash with logo
│   ├── library_screen.dart   # Main library view
│   ├── book_detail_screen.dart  # Book words & input
│   └── add_book_screen.dart  # Add new book form
├── services/
│   ├── perplexity_service.dart  # AI API integration
│   └── storage_service.dart     # Local persistence
├── theme/
│   └── app_theme.dart        # Design tokens & themes
└── widgets/
    ├── book_card.dart        # Book display card
    ├── contexta_app_bar.dart # Custom app bar
    ├── contexta_bottom_sheet.dart  # Modal sheets
    ├── contexta_dialog.dart  # Confirmation dialogs
    ├── contexta_text_field.dart    # Styled inputs
    ├── loading_dots.dart     # Animated loader
    ├── logo.dart             # Brand logo widget
    ├── primary_button.dart   # Primary CTA button
    ├── secondary_button.dart # Secondary button
    ├── word_explanation_sheet.dart  # Word detail modal
    └── word_list_item.dart   # Word collection item
```

### State Management

The app uses **lifting state up** pattern with StatefulWidgets:
- Books list managed in `main.dart`
- Passed down to screens via constructor
- Callbacks bubble up state changes
- `StorageService` handles persistence

### Data Flow

```
User Action → Screen Widget → Callback to Main → 
State Update → StorageService.save() → UI Rebuild
```

### API Integration

**Perplexity API** is used for contextual word explanations:
- Model: `sonar`
- Max tokens: 300
- Temperature: 0.3 (focused responses)
- Custom system prompt for literary context

---

## Design System

### Philosophy

Contexta's design follows a **"quiet luxury"** aesthetic — elegant, understated, and focused on content. The interface should feel like a well-crafted journal, not a tech product.

### Color Palette

#### Light Mode
| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#F5F0E8` | Warm beige paper |
| Surface | `#FFFFFF` | Cards, sheets |
| Ink Blue | `#1A4B7C` | Primary accent |
| Text Primary | `#2D2D2D` | Main text |
| Text Secondary | `#6B6B6B` | Supporting text |
| Border | `#E5E0D8` | Subtle dividers |

#### Dark Mode
| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#1A1A1A` | Deep charcoal |
| Surface | `#2A2A2A` | Elevated surfaces |
| Light Ink Blue | `#7B8AB5` | Primary accent |
| Text Primary | `#F5F0E8` | Main text |
| Text Secondary | `#A0A0A0` | Supporting text |
| Border | `#3A3A3A` | Subtle dividers |

### Typography

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| Display | Georgia (Serif) | 28px | 500 | Screen titles |
| Headline | Georgia (Serif) | 24px | 500 | Section headers |
| Body | Inter | 16px | 400 | Main content |
| Caption | Inter | 14px | 400 | Secondary info |
| Button | Inter | 15px | 500 | Button labels |

### Spacing Scale

- `4px` - Micro spacing
- `8px` - Tight spacing
- `12px` - Compact spacing
- `16px` - Default spacing
- `24px` - Relaxed spacing
- `32px` - Section spacing
- `48px` - Large gaps

### Border Radius

- Small: `8px` - Buttons, inputs
- Medium: `12px` - Cards
- Large: `16px` - Sheets, modals
- XLarge: `24px` - Pills, FAB

### Animations

| Animation | Duration | Curve | Usage |
|-----------|----------|-------|-------|
| Fade In | 700ms | easeOut | Screen transitions |
| Button Press | 100ms | easeOut | Tap feedback |
| Sheet Enter | 300ms | easeOut | Bottom sheets |
| Loading Dots | 600ms | easeInOut | API loading |

### Logo

The Contexta logo combines three elements:
1. **Page corner fold** (top-right) - Represents reading
2. **C-shaped bracket** - Annotation/marginalia symbol
3. **Margin line** (left) - Scholarly annotation style

Built with `CustomPaint` for crisp rendering at any size.

---

## Dependencies

```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8     # iOS-style icons
  http: ^1.2.0                 # HTTP client for API
  shared_preferences: ^2.2.2   # Local storage
  flutter_dotenv: ^5.1.0       # Environment config

dev_dependencies:
  flutter_test: sdk
  flutter_lints: ^5.0.0        # Linting rules
  flutter_launcher_icons: ^0.14.3  # Icon generation
  image: ^4.1.3                # Image processing
```

---

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PERPLEXITY_API_KEY` | API key for Perplexity AI | Yes |

### API Configuration

Located in `lib/config/api_config.dart`:

```dart
static const String perplexityModel = 'sonar';
static const int maxTokens = 300;
static const double temperature = 0.3;
static const Duration requestTimeout = Duration(seconds: 30);
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Perplexity AI** for the contextual explanation API
- **Flutter Team** for the amazing framework
- Design inspiration from minimalist reading apps and physical journals

---

<p align="center">
  Made with 📚 for curious readers
</p>
