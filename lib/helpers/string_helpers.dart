/// Removes everything but numbers from a string
String removeEverythingButNumbers(String text) {
  return text.replaceAll(RegExp(r'[^0-9]'), '').trim();
}

/// Converts a string to title case
/// Example: "hello world" -> "Hello World"
String titleCase(String input) {
  if (input.isEmpty) return input;
  return input
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase(),
      )
      .join(' ');
}

/// Returns null if text is null, undefined, or empty (after trim), otherwise returns trimmed text
String? nullIfEmpty(String? text) {
  if (text == null) {
    return null;
  }
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Removes leading zeros from a string
/// Example: "000123" -> "123"
String removeLeadingZeros(String text) {
  return text.replaceFirst(RegExp(r'^0+'), '');
}



