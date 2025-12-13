/// Extracts a number from a string that may have symbols at the end
/// Removes all non-numeric characters except for potential negative sign at start
/// Example: "1000.50$" -> 1000.50
double numberFromNumberWithSymbolAtTheEnd(String input) {
  if (input.isEmpty) return 0.0;
  // Remove all non-numeric characters except for potential negative sign at start
  final cleaned = input.replaceAll(RegExp(r'[^0-9.-]'), '');
  return double.tryParse(cleaned) ?? 0.0;
}



