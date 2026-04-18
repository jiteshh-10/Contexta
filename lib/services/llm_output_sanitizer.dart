/// Enforces plain text output style from LLM responses.
class LlmOutputSanitizer {
  LlmOutputSanitizer._();

  static String normalizePlainText(String input) {
    var text = input.replaceAll('\r\n', '\n').trim();

    // Remove markdown emphasis artifacts.
    text = text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'__(.*?)__'), r'$1')
        .replaceAll(RegExp(r'_(.*?)_'), r'$1')
        .replaceAll('`', '');

    // Normalize long dash variants to simple hyphen.
    text = text.replaceAll('—', '-').replaceAll('–', '-');

    return text.trim();
  }
}
