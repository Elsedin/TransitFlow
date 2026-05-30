import 'dart:convert';

class ApiError {
  static String fromResponseBody(
    String body, {
    String fallback = 'Došlo je do greške',
  }) {
    if (body.trim().isEmpty) {
      return fallback;
    }

    try {
      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic>) {
        return fallback;
      }

      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final title = decoded['title'];
      if (title is String && title.trim().isNotEmpty && decoded['errors'] == null) {
        return title.trim();
      }

      final errors = decoded['errors'];
      if (errors is Map<String, dynamic>) {
        final parts = <String>[];
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            parts.add('${entry.key}: ${value.first}');
          } else if (value is String && value.isNotEmpty) {
            parts.add('${entry.key}: $value');
          }
        }
        if (parts.isNotEmpty) {
          return parts.join('\n');
        }
      }
    } catch (_) {}

    return fallback;
  }

  static String fromException(
    Object error, {
    String fallback = 'Došlo je do greške',
  }) {
    final text = error.toString().trim();
    if (text.isEmpty) {
      return fallback;
    }

    const prefix = 'Exception: ';
    if (text.startsWith(prefix)) {
      final message = text.substring(prefix.length).trim();
      return message.isEmpty ? fallback : message;
    }

    return text;
  }
}
