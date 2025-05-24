import 'package:dio/dio.dart';
import 'package:mediasink_app/api/rest_client.dart';
import 'package:mediasink_app/factories/rest_client_factory.dart';
import 'package:mediasink_app/services/auth_service.dart';
import 'package:mediasink_app/services/settings_service.dart';
import 'package:mediasink_app/services/websocket_service.dart';
import 'package:mediasink_app/services/token_manager.dart';

class FullBootstrapServices {
  final Dio dio;
  final SettingsService settingsService;
  final TokenManager tokenManager;
  final RestClientFactory restClientFactory;
  final RestClient restClient;
  final AuthService authService;
  final WebSocketService webSocketService;

  FullBootstrapServices({required this.dio, required this.settingsService, required this.tokenManager, required this.restClientFactory, required this.restClient, required this.authService, required this.webSocketService});
}

class MinimalBootstrapServices {
  final Dio dio;
  final SettingsService settingsService;
  final TokenManager tokenManager;
  final RestClientFactory restClientFactory;

  MinimalBootstrapServices({required this.dio, required this.settingsService, required this.tokenManager, required this.restClientFactory});
}

Future<MinimalBootstrapServices> minimalBootstrap() async {
  final settingsService = await SettingsService.create();
  final dio = Dio();
  final tokenManager = TokenManager();
  final restClientFactory = RestClientFactory(dio: dio, settingsService: settingsService, tokenManager: tokenManager);

  return MinimalBootstrapServices(settingsService: settingsService, dio: dio, restClientFactory: restClientFactory, tokenManager: tokenManager);
}

Future<FullBootstrapServices> fullBootstrap(SettingsService settingsService) async {
  final dio = Dio();
  final tokenManager = TokenManager();
  final restClientFactory = RestClientFactory(dio: dio, settingsService: settingsService, tokenManager: tokenManager);
  final restClient = await restClientFactory.create();
  final authService = AuthService(settingsService, restClient);
  final webSocketService = WebSocketService(settingsService, authService);
  await webSocketService.connect();

  return FullBootstrapServices(dio: dio, settingsService: settingsService, tokenManager: tokenManager, restClientFactory: restClientFactory, restClient: restClient, authService: authService, webSocketService: webSocketService);
}