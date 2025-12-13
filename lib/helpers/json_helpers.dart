import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

/// Canonical JSON serialization - normalizes and sorts object keys
/// Returns a canonical JSON string representation of the input
String canonicalJson(dynamic input) {
  dynamic normalize(dynamic x) {
    if (x is List) {
      return x.map((item) => normalize(item)).toList();
    }
    if (x is Map) {
      final sortedKeys = (x.keys as Iterable<String>).toList()
        ..sort((a, b) => a.compareTo(b));
      final result = <String, dynamic>{};
      for (final k in sortedKeys) {
        final v = x[k];
        if (v != null) {
          result[k] = normalize(v);
        }
      }
      return result;
    }
    return x;
  }
  return jsonEncode(normalize(input));
}

/// Compute SHA256 hash and return base64 encoded result
/// [s] The string to hash
/// Returns Base64 encoded SHA256 hash
String sha256Base64(String s) {
  final bytes = utf8.encode(s);
  final digest = crypto.sha256.convert(bytes);
  return base64Encode(digest.bytes);
}

/// Canonical query key generation from parameters
/// [params] Optional map of query parameters
/// Returns Map with queryParams and queryParamsHash, or empty map if no params
Map<String, String> canonicalQueryKey([Map<String, dynamic>? params]) {
  if (params == null || params.isEmpty) {
    return {};
  }

  final flat = <String, String>{};
  for (final entry in params.entries) {
    if (entry.value == null) continue;
    final key = Uri.encodeComponent(entry.key.toLowerCase());
    if (entry.value is List) {
      final list = entry.value as List;
      flat[key] = list.map((i) => Uri.encodeComponent(i.toString())).join(',');
    } else {
      flat[key] = Uri.encodeComponent(entry.value.toString());
    }
  }

  final keys = flat.keys.toList()..sort();
  if (keys.isEmpty) return {};

  final queryParams = keys.map((k) => '$k=${flat[k]}').join('&');
  final queryParamsHash = sha256Base64(queryParams);

  return {
    'queryParams': queryParams,
    'queryParamsHash': queryParamsHash,
  };
}

