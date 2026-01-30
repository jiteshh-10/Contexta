import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/book.dart';
import '../models/word_entry.dart';

/// Export format options
enum ExportFormat {
  plainText('Plain Text', 'txt', 'text/plain'),
  markdown('Markdown', 'md', 'text/markdown'),
  pdf('PDF Document', 'pdf', 'application/pdf');

  final String label;
  final String extension;
  final String mimeType;
  const ExportFormat(this.label, this.extension, this.mimeType);
}

/// Export scope options
enum ExportScope {
  singleBook('This Book'),
  allBooks('All Books');

  final String label;
  const ExportScope(this.label);
}

/// Result of an export operation
class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int wordCount;

  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
    this.wordCount = 0,
  });

  factory ExportResult.success(String filePath, int wordCount) {
    return ExportResult(
      success: true,
      filePath: filePath,
      wordCount: wordCount,
    );
  }

  factory ExportResult.failure(String error) {
    return ExportResult(success: false, error: error);
  }
}

/// Service for exporting words to files
class ExportService {
  ExportService._();
  static final ExportService _instance = ExportService._();
  factory ExportService() => _instance;

  /// Generate filename with proper naming convention
  String _generateFileName({required ExportFormat format, String? bookTitle}) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (bookTitle != null) {
      // Sanitize book title for filename
      final sanitizedFull = bookTitle
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(
            RegExp(r'^_+|_+$'),
            '',
          ); // Trim leading/trailing underscores
      // Limit to 30 characters (using sanitized length)
      final sanitized =
          sanitizedFull.length > 30
              ? sanitizedFull.substring(0, 30)
              : sanitizedFull;
      return '${sanitized}_words_$dateStr.${format.extension}';
    } else {
      return 'contexta_vocabulary_$dateStr.${format.extension}';
    }
  }

  /// Generate plain text content for a single book
  String _generatePlainTextForBook(Book book) {
    if (book.words.isEmpty) {
      return 'No words saved for "${book.title}" yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      '═══════════════════════════════════════════════════════════',
    );
    buffer.writeln('  ${book.title.toUpperCase()}');
    buffer.writeln('  by ${book.author}');
    buffer.writeln(
      '═══════════════════════════════════════════════════════════',
    );
    buffer.writeln();
    buffer.writeln('${book.words.length} words captured');
    buffer.writeln();
    buffer.writeln(
      '───────────────────────────────────────────────────────────',
    );
    buffer.writeln();

    // Sort words alphabetically
    final sortedWords = [...book.words];
    sortedWords.sort(
      (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
    );

    for (final word in sortedWords) {
      buffer.writeln('▸ ${word.capitalizedWord}');
      buffer.writeln('  ${word.explanation}');
      if (word.difficultyReason != null) {
        buffer.writeln('  [${word.difficultyReason!.label}]');
      }
      buffer.writeln();
    }

    buffer.writeln(
      '───────────────────────────────────────────────────────────',
    );
    buffer.writeln('Exported from Contexta');
    buffer.writeln('${DateTime.now().toString().split('.')[0]}');

    return buffer.toString();
  }

  /// Generate plain text content for all books
  String _generatePlainTextForAllBooks(List<Book> books) {
    final booksWithWords = books.where((b) => b.hasWords).toList();

    if (booksWithWords.isEmpty) {
      return 'No words saved in your library yet.';
    }

    final totalWords = booksWithWords.fold<int>(
      0,
      (sum, b) => sum + b.wordCount,
    );
    final buffer = StringBuffer();

    buffer.writeln(
      '╔═══════════════════════════════════════════════════════════╗',
    );
    buffer.writeln(
      '║              CONTEXTA VOCABULARY EXPORT                    ║',
    );
    buffer.writeln(
      '╚═══════════════════════════════════════════════════════════╝',
    );
    buffer.writeln();
    buffer.writeln('$totalWords words from ${booksWithWords.length} books');
    buffer.writeln();

    for (final book in booksWithWords) {
      buffer.writeln(
        '═══════════════════════════════════════════════════════════',
      );
      buffer.writeln('  ${book.title.toUpperCase()}');
      buffer.writeln('  by ${book.author}');
      buffer.writeln('  (${book.wordCount} words)');
      buffer.writeln(
        '═══════════════════════════════════════════════════════════',
      );
      buffer.writeln();

      final sortedWords = [...book.words];
      sortedWords.sort(
        (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
      );

      for (final word in sortedWords) {
        buffer.writeln('▸ ${word.capitalizedWord}');
        buffer.writeln('  ${word.explanation}');
        if (word.difficultyReason != null) {
          buffer.writeln('  [${word.difficultyReason!.label}]');
        }
        buffer.writeln();
      }
    }

    buffer.writeln(
      '───────────────────────────────────────────────────────────',
    );
    buffer.writeln('Exported from Contexta');
    buffer.writeln('${DateTime.now().toString().split('.')[0]}');

    return buffer.toString();
  }

  /// Generate markdown content for a single book
  String _generateMarkdownForBook(Book book) {
    if (book.words.isEmpty) {
      return '# ${book.title}\n\n*No words saved yet.*';
    }

    final buffer = StringBuffer();
    buffer.writeln('# ${book.title}');
    buffer.writeln('*by ${book.author}*');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('**${book.words.length} words captured**');
    buffer.writeln();

    // Sort words alphabetically
    final sortedWords = [...book.words];
    sortedWords.sort(
      (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
    );

    for (final word in sortedWords) {
      buffer.writeln('## ${word.capitalizedWord}');
      buffer.writeln();
      buffer.writeln(word.explanation);
      if (word.difficultyReason != null) {
        buffer.writeln();
        buffer.writeln('> 📌 *${word.difficultyReason!.label}*');
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(
      '*Exported from [Contexta](https://github.com/jiteshh-10/Contexta) on ${DateTime.now().toString().split('.')[0]}*',
    );

    return buffer.toString();
  }

  /// Generate markdown content for all books
  String _generateMarkdownForAllBooks(List<Book> books) {
    final booksWithWords = books.where((b) => b.hasWords).toList();

    if (booksWithWords.isEmpty) {
      return '# My Vocabulary\n\n*No words saved in your library yet.*';
    }

    final totalWords = booksWithWords.fold<int>(
      0,
      (sum, b) => sum + b.wordCount,
    );
    final buffer = StringBuffer();

    buffer.writeln('# 📚 My Contexta Vocabulary');
    buffer.writeln();
    buffer.writeln(
      '**$totalWords words** from **${booksWithWords.length} books**',
    );
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Table of contents
    buffer.writeln('## Table of Contents');
    buffer.writeln();
    for (final book in booksWithWords) {
      final anchor = book.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '-');
      buffer.writeln('- [${book.title}](#$anchor) (${book.wordCount} words)');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (final book in booksWithWords) {
      buffer.writeln('# ${book.title}');
      buffer.writeln('*by ${book.author}*');
      buffer.writeln();

      final sortedWords = [...book.words];
      sortedWords.sort(
        (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
      );

      for (final word in sortedWords) {
        buffer.writeln('### ${word.capitalizedWord}');
        buffer.writeln();
        buffer.writeln(word.explanation);
        if (word.difficultyReason != null) {
          buffer.writeln();
          buffer.writeln('> 📌 *${word.difficultyReason!.label}*');
        }
        buffer.writeln();
      }

      buffer.writeln('---');
      buffer.writeln();
    }

    buffer.writeln(
      '*Exported from [Contexta](https://github.com/jiteshh-10/Contexta) on ${DateTime.now().toString().split('.')[0]}*',
    );

    return buffer.toString();
  }

  /// Generate export content based on format and scope (text formats only)
  String generateContent({
    required ExportFormat format,
    Book? book,
    List<Book>? books,
  }) {
    if (format == ExportFormat.pdf) {
      // PDF doesn't return string content, return preview text instead
      return _generatePlainTextPreview(book: book, books: books);
    }

    if (book != null) {
      // Single book export
      return format == ExportFormat.plainText
          ? _generatePlainTextForBook(book)
          : _generateMarkdownForBook(book);
    } else if (books != null) {
      // All books export
      return format == ExportFormat.plainText
          ? _generatePlainTextForAllBooks(books)
          : _generateMarkdownForAllBooks(books);
    }
    return '';
  }

  /// Generate a simple preview text for PDF format
  String _generatePlainTextPreview({Book? book, List<Book>? books}) {
    final buffer = StringBuffer();
    if (book != null) {
      buffer.writeln('📄 PDF Export');
      buffer.writeln();
      buffer.writeln('${book.title}');
      buffer.writeln('by ${book.author}');
      buffer.writeln();
      buffer.writeln('${book.wordCount} words will be exported as a');
      buffer.writeln('beautifully formatted PDF document.');
    } else if (books != null) {
      final booksWithWords = books.where((b) => b.hasWords).toList();
      final totalWords = booksWithWords.fold<int>(
        0,
        (sum, b) => sum + b.wordCount,
      );
      buffer.writeln('📄 PDF Export');
      buffer.writeln();
      buffer.writeln('Complete Vocabulary Collection');
      buffer.writeln();
      buffer.writeln('$totalWords words from ${booksWithWords.length} books');
      buffer.writeln('will be exported as a beautifully');
      buffer.writeln('formatted PDF document.');
    }
    return buffer.toString();
  }

  /// Export and share words
  Future<ExportResult> exportAndShare({
    required ExportFormat format,
    Book? book,
    List<Book>? books,
  }) async {
    try {
      debugPrint('ExportService: Starting export with format ${format.label}');

      // Calculate word count
      int wordCount = 0;
      if (book != null) {
        wordCount = book.wordCount;
      } else if (books != null) {
        wordCount = books.fold<int>(0, (sum, b) => sum + b.wordCount);
      }

      if (wordCount == 0) {
        debugPrint('ExportService: No words to export');
        return ExportResult.failure('No words to export');
      }

      debugPrint('ExportService: Exporting $wordCount words');

      // Generate filename
      final fileName = _generateFileName(
        format: format,
        bookTitle: book?.title,
      );
      debugPrint('ExportService: Generated filename: $fileName');

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      debugPrint('ExportService: File path: $filePath');

      // Create file based on format
      if (format == ExportFormat.pdf) {
        // Generate PDF
        debugPrint('ExportService: Generating PDF...');
        final pdfBytes = await _generatePdf(book: book, books: books);
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        debugPrint('ExportService: PDF written (${pdfBytes.length} bytes)');
      } else {
        // Generate text content
        debugPrint('ExportService: Generating text content...');
        final content = generateContent(
          format: format,
          book: book,
          books: books,
        );
        final file = File(filePath);
        await file.writeAsString(content);
        debugPrint(
          'ExportService: Text content written (${content.length} chars)',
        );
      }

      // Share the file
      debugPrint('ExportService: Opening share dialog...');
      final shareResult = await Share.shareXFiles(
        [XFile(filePath, mimeType: format.mimeType)],
        subject:
            book != null
                ? 'Words from "${book.title}"'
                : 'My Contexta Vocabulary',
      );
      debugPrint(
        'ExportService: Share completed with status: ${shareResult.status}',
      );

      // All share results are considered success (user may dismiss after saving)
      return ExportResult.success(filePath, wordCount);
    } catch (e, stackTrace) {
      debugPrint('ExportService: Export failed: $e');
      debugPrint('ExportService: Stack trace: $stackTrace');
      return ExportResult.failure('Export failed: ${e.toString()}');
    }
  }

  /// Generate PDF document
  Future<List<int>> _generatePdf({Book? book, List<Book>? books}) async {
    final pdf = pw.Document();

    // PDF styles
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    );
    final authorStyle = pw.TextStyle(
      fontSize: 14,
      fontStyle: pw.FontStyle.italic,
      color: PdfColors.grey700,
    );
    final wordStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );
    final explanationStyle = pw.TextStyle(
      fontSize: 12,
      color: PdfColors.grey800,
    );
    final badgeStyle = pw.TextStyle(
      fontSize: 10,
      fontStyle: pw.FontStyle.italic,
      color: PdfColors.blueGrey600,
    );

    if (book != null) {
      // Single book PDF
      _addBookToPdf(
        pdf,
        book,
        titleStyle,
        authorStyle,
        wordStyle,
        explanationStyle,
        badgeStyle,
      );
    } else if (books != null) {
      // All books PDF - add cover page
      final booksWithWords = books.where((b) => b.hasWords).toList();
      final totalWords = booksWithWords.fold<int>(
        0,
        (sum, b) => sum + b.wordCount,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build:
              (context) => pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Vocabulary Collection',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Exported from Contexta',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(20),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '$totalWords Words',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'from ${booksWithWords.length} Books',
                            style: pw.TextStyle(
                              fontSize: 16,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 60),
                    pw.Text(
                      _formatDate(DateTime.now()),
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      );

      // Add each book
      for (final bk in booksWithWords) {
        _addBookToPdf(
          pdf,
          bk,
          titleStyle,
          authorStyle,
          wordStyle,
          explanationStyle,
          badgeStyle,
        );
      }
    }

    return pdf.save();
  }

  /// Add a book's words to the PDF
  void _addBookToPdf(
    pw.Document pdf,
    Book book,
    pw.TextStyle titleStyle,
    pw.TextStyle authorStyle,
    pw.TextStyle wordStyle,
    pw.TextStyle explanationStyle,
    pw.TextStyle badgeStyle,
  ) {
    final sortedWords = [...book.words];
    sortedWords.sort(
      (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
    );

    // Build word widgets
    final wordWidgets = <pw.Widget>[];

    for (final word in sortedWords) {
      wordWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(word.capitalizedWord, style: wordStyle),
              pw.SizedBox(height: 6),
              pw.Text(word.explanation, style: explanationStyle),
              if (word.difficultyReason != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('${word.difficultyReason!.label}', style: badgeStyle),
              ],
              if (word.lookupCount > 1) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  'Encountered ${word.lookupCount} times',
                  style: badgeStyle,
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Add pages with header
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header:
            (context) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(book.title, style: titleStyle),
                      pw.Text('by ${book.author}', style: authorStyle),
                    ],
                  ),
                  pw.Text(
                    '${book.wordCount} words',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
        footer:
            (context) => pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              ),
            ),
        build: (context) => wordWidgets,
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Preview export content (for display before sharing)
  String previewContent({
    required ExportFormat format,
    Book? book,
    List<Book>? books,
    int maxLines = 20,
  }) {
    final content = generateContent(format: format, book: book, books: books);
    final lines = content.split('\n');
    if (lines.length <= maxLines) return content;
    return '${lines.take(maxLines).join('\n')}\n\n... and more';
  }
}
