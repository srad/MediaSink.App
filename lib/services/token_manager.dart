import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();

  factory TokenManager() => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _accessToken;

  TokenManager._internal();

  Future<String?> getToken({RequestsAuthenticationRequest? auth}) async {
    if (_accessToken != null) return _accessToken;

    String? username, password;
    if (auth == null) {
      username = await _secureStorage.read(key: 'server_username');
      password = await _secureStorage.read(key: 'server_password');
    } else {
      username = auth.username;
      password = auth.password;
    }

    if (username == null || password == null) {
      throw Exception('Credentials missing');
    }

    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('serverUrl');
    final baseUrl = '$serverUrl/api/v1';

    final authClient = RestClient(Dio(), baseUrl: baseUrl);
    final response = await authClient.auth.postAuthLogin(authenticationRequest: RequestsAuthenticationRequest(username: username, password: password));

    _accessToken = response.token;
    return _accessToken;
  }

  void clearToken() {
    _accessToken = null;
  }
}
