import 'package:dio/dio.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/api/rest_client.dart';
import 'package:mediasink_app/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestClientFactory {
  static final Dio _dio = Dio();

  // Optionally pass credentials as arguments, otherwise taken from secure storage.
  static Future<RestClient> create({RequestsAuthenticationRequest? auth}) async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('serverUrl');
    final baseUrl = '$serverUrl/api/v1';

    // Add interceptors only once. On startup Dio already has one.
    if (_dio.interceptors.length == 1) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            try {
              final token = await TokenManager().getToken(auth: auth);
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              return handler.next(options);
            } catch (e, s) {
              final dioError = DioException(
                requestOptions: options,
                error: e,
                stackTrace: s,
                type: DioExceptionType.unknown, //
              );
              return handler.reject(dioError);
            }
          },
          onError: (error, handler) async {
            // Only retry if it's a 401 and not already a retry attempt
            if (error.response?.statusCode == 401) {
              try {
                TokenManager().clearToken();
                // Try get new token again
                final token = await TokenManager().getToken(auth: auth);

                if (token != null) {
                  error.requestOptions.headers['Authorization'] = 'Bearer $token';
                  final clonedRequest = await _dio.fetch(error.requestOptions);
                  return handler.resolve(clonedRequest);
                } else {
                  // If we can't get a new token (e.g., auth still fails),
                  // don't retry, just pass the original 401 error.
                  return handler.next(error);
                }
              } catch (e, s) {
                // If getting the token fails *during* the retry attempt,
                // we can't recover. We should reject with a new error
                // that includes the original request and the new exception.
                final newError = DioException(
                  requestOptions: error.requestOptions,
                  error: e,
                  stackTrace: s,
                  type: DioExceptionType.unknown,
                  response: error.response, // Keep original response context
                );
                // Reject retry attempt
                return handler.reject(newError);
              }
            }
            // For any other error, just pass it along.
            return handler.next(error);
          },
        ),
      );
    }

    return RestClient(_dio, baseUrl: baseUrl);
  }
}
