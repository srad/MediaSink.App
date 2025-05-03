import 'package:http/http.dart' as http;

Future<bool> checkServerAvailable(Uri url) async {
  try {
    final response = await http.head(url).timeout(const Duration(seconds: 3));
    return response.statusCode < 500; // 200–499 means server is reachable
  } catch (_) {
    return false;
  }
}