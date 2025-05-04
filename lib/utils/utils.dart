import 'package:http/http.dart' as http;

Future<bool> checkServerAvailable(Uri url) async {
  try {
    final response = await http.head(url).timeout(const Duration(seconds: 3));
    return response.statusCode < 500; // 200–499 means server is reachable
  } catch (_) {
    return false;
  }
}

String? tagValidator(String? value) {
  if (value == null || value.isEmpty) return null;

  final tags = value.split(',').map((tag) => tag.trim());
  final tagRegex = RegExp(r'^[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*$');

  for (var tag in tags) {
    if (!tagRegex.hasMatch(tag)) {
      return 'Invalid tag: "$tag". Tags must be alphanumeric, may include single "-" (not at start/end or chained), and no underscores.';
    }
  }

  return null;
}

String extractLongestAlphanumUnderscore(String url) {
  final regex = RegExp(r'[a-zA-Z0-9_]+');
  final matches = regex.allMatches(url);

  String? longest;
  for (final match in matches) {
    final matchStr = match.group(0)!;
    if (longest == null || matchStr.length > longest.length) {
      longest = matchStr;
    }
  }
  return longest ?? '';
}