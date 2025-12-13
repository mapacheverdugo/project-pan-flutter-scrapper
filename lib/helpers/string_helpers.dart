/// Removes everything but numbers from a string
String removeEverythingButNumbers(String input) {
  return input.replaceAll(RegExp(r'[^0-9]'), '');
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



