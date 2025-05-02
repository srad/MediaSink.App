import 'api_client.dart';

class ApiClientFactory {
  static final ApiClientFactory _instance = ApiClientFactory._internal();
  ApiClient? _client;
  Future<ApiClient>? _initializing;

  ApiClientFactory._internal();

  factory ApiClientFactory() {
    return _instance;
  }

  Future<ApiClient> create() async {
    // Return already initialized client
    if (_client != null) return _client!;

    // Prevent duplicate initializations
    if (_initializing != null) return _initializing!;

    _initializing = _initializeClient();
    return _initializing!;
  }

  Future<ApiClient> _initializeClient() async {
    final client = ApiClient(); // Initialization is handled lazily inside ApiClient
    _client = client;
    _initializing = null;
    return client;
  }

  void resetClient() {
    _client = null;
    _initializing = null;
  }
}
