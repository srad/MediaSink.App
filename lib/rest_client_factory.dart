import 'package:dio/dio.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/api/rest_client.dart';
import 'package:mediasink_app/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
