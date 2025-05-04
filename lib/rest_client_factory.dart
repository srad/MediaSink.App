import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/api/rest_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();

  factory TokenManager() => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _accessToken;

  TokenManager._internal();

  Future<String?> getToken() async {
    if (_accessToken != null) return _accessToken;

    final username = await _secureStorage.read(key: 'server_username');
    final password = await _secureStorage.read(key: 'server_password');

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

class RestClientFactory {
  static final Dio _dio = Dio();

  static Future<RestClient> create() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('serverUrl');
    final baseUrl = '$serverUrl/api/v1';

    // Add interceptors only once. On startup Dio already has one.
    if (_dio.interceptors.length == 1) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await TokenManager().getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              TokenManager().clearToken();
              final token = await TokenManager().getToken();

              if (token != null) {
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                final clonedRequest = await _dio.fetch(error.requestOptions);
                return handler.resolve(clonedRequest);
              }
            }
            return handler.next(error);
          },
        ),
      );
    }

    return RestClient(_dio, baseUrl: baseUrl);
  }
}
