import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<void> copyHtmlToClipboard(String body) async {
  if (kDebugMode) {
    Clipboard.setData(ClipboardData(text: body));
  }
}
