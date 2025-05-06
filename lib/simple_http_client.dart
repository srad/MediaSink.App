import 'package:dio/dio.dart';
import 'package:mediasink_app/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleHttpClientFactory {
  static Dio? _dio;

  static Future<Dio> create() async {
    if (_dio == null) {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('serverUrl');
      final baseUrl = '$serverUrl/api/v1';

      _dio = Dio(BaseOptions(baseUrl: baseUrl));

      _dio!.interceptors.add(
        InterceptorsWrapper(
          // Adding Authorization header for every request
          onRequest: (options, handler) async {
            try {
              final token = await TokenManager().getToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (e) {
              // Handle cases where getting token fails, e.g. no internet, storage issue, etc.
              print('Error fetching token: $e');
            }
            return handler.next(options);
          },

          // Handle 401 errors, refresh token, and retry the request
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              // Clear token and fetch a new one
              TokenManager().clearToken();

              try {
                final token = await TokenManager().getToken();
                if (token != null) {
                  // Retry the request with the new token
                  error.requestOptions.headers['Authorization'] = 'Bearer $token';
                  final clonedRequest = await _dio!.fetch(error.requestOptions);
                  return handler.resolve(clonedRequest);  // Resolve with the new response
                }
              } catch (e) {
                // Handle error (e.g. unable to refresh token)
                print('Error refreshing token: $e');
              }
            }

            return handler.next(error); // Continue with error handling
          },
        ),
      );
    }

    return _dio!;
  }
}
