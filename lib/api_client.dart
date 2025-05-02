import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  String? _token;
  String? _baseUrl;
  final http.Client _httpClient = http.Client();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('serverUrl');
    _baseUrl = '$serverUrl/api/v1';

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw Exception('Server URL is missing');
    }

    await _authenticate(); // initial auth
    _isInitialized = true;
  }

  Future<void> _authenticate() async {
    final username = await _secureStorage.read(key: 'server_username');
    final password = await _secureStorage.read(key: 'server_password');

    if (username == null || password == null) {
      throw Exception('Credentials missing');
    }

    final loginUrl = Uri.parse('$_baseUrl/auth/login');
    final response = await _httpClient.post(loginUrl, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': username, 'password': password}));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _token = responseData['token'];
    } else {
      throw Exception('Authentication failed: ${response.statusCode}');
    }
  }

  Future<void> pause(int id) async {
    await post('/channels/$id/pause', {});
  }

  Future<void> resume(int id) async {
    await post('/channels/$id/resume', {});
  }

  Future<void> unfavChannel(int id) async {
    await post('/channels/$id/unfav', {});
  }

  Future<void> favChannel(int id) async {
    await post('/channels/$id/fav', {});
  }

  Map<String, String> _authHeaders() {
    return {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'};
  }

  Future<http.Response> _sendWithRetry(Future<http.Response> Function() request) async {
    http.Response response = await request();

    if (response.statusCode == 401) {
      // Token expired, try to re-authenticate and retry once
      await _authenticate();
      response = await request(); // retry once
    }

    return response;
  }

  Future<http.Response> get(String endpoint) async {
    await _initialize();
    final url = Uri.parse('$_baseUrl$endpoint');
    return _sendWithRetry(() => _httpClient.get(url, headers: _authHeaders()));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    await _initialize();
    final url = Uri.parse('$_baseUrl$endpoint');
    return _sendWithRetry(() => _httpClient.post(url, headers: _authHeaders(), body: jsonEncode(body)));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    await _initialize();
    final url = Uri.parse('$_baseUrl$endpoint');
    return _sendWithRetry(() => _httpClient.put(url, headers: _authHeaders(), body: jsonEncode(body)));
  }

  Future<http.Response> delete(String endpoint) async {
    await _initialize();
    final url = Uri.parse('$_baseUrl$endpoint');
    return _sendWithRetry(() => _httpClient.delete(url, headers: _authHeaders()));
  }
}
