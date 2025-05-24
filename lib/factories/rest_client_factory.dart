import 'package:dio/dio.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/api/rest_client.dart';
import 'package:mediasink_app/services/settings_service.dart';
import 'package:mediasink_app/services/token_manager.dart';

class RestClientFactory {
  final Dio _dio;
  final SettingsService _settingsService;
  final TokenManager _tokenManager;
  bool _interceptorsAdded = false;

  RestClientFactory({
    required Dio dio,
    required SettingsService settingsService,
    required TokenManager tokenManager,
  })  : _dio = dio,
        _settingsService = settingsService,
        _tokenManager = tokenManager;

  // Optionally pass credentials as arguments, otherwise taken from secure storage.
  Future<RestClient> create() async {
    final serverUrl = await _settingsService.getServerUrl();
    final effectiveBaseUrl = serverUrl != null ? '$serverUrl/api/v1' : null;

    if (effectiveBaseUrl != null) {
      _dio.options.baseUrl = effectiveBaseUrl;
    } else {
      // Decide behavior if URL is null (throw error, or RestClient handles it)
      // For now, let's assume RestClient needs a valid URL from Dio's options
      if (_dio.options.baseUrl.isEmpty) {
        throw Exception("Server URL is not configured and Dio has no default base URL.");
      }
    }

    final auth = await _settingsService.getAuthCredentials();

    // Add interceptors only once. On startup Dio already has one.
    if (!_interceptorsAdded) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            try {
              final token = await TokenManager().getToken(auth: RequestsAuthenticationRequest(username: auth?.$1, password: auth?.$2));
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
                final token = await TokenManager().getToken(auth: RequestsAuthenticationRequest(username: auth?.$1, password: auth?.$2));

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
      _interceptorsAdded = true;
    }

    return RestClient(_dio, baseUrl: _dio.options.baseUrl);
  }
}
