import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/services/settings_service.dart';

class AuthService extends ChangeNotifier {
  // AuthService now depends on SettingsService to get username/password
  final SettingsService _settingsService;
  final RestClient _client;

  // It can still manage the JWT (ws_jwt) itself, or this too could be moved
  // to SettingsService if you want ALL app secrets/tokens in one place.
  // For this example, JWT storage remains in AuthService.
  final _jwtSecureStorage = const FlutterSecureStorage(); // Potentially rename if confusing
  final _jwtStorageKey = 'ws_jwt';

  // Constructor now requires SettingsService
  AuthService(this._settingsService, this._client);

  Future<String?> getCurrentJwt() async {
    return await _jwtSecureStorage.read(key: _jwtStorageKey);
  }

  Future<bool> hasToken() async {
    final jwt = await getCurrentJwt();
    return jwt != null && jwt.isNotEmpty;
  }

  Future<void> login() async {
    // ---- MODIFIED SECTION ----
    // Get username and password from SettingsService
    final username = await _settingsService.getUsername();
    final password = await _settingsService.getPassword();

    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      debugPrint("AuthService: Username or password not found in settings.");
      throw Exception("Login credentials not configured in settings.");
    }
    // ---- END MODIFIED SECTION ----

    // The rest of the login logic can remain similar,
    // assuming RestClientFactory is either configured with the HTTP base URL
    // from SettingsService or doesn't need it for the auth call itself.
    // If RestClientFactory also needs the server_url, it might also need SettingsService.
    final authRequest = RequestsAuthenticationRequest(username: username, password: password);

    try {
      final response = await _client.auth.postAuthLogin(authenticationRequest: authRequest);
      final jwt = response.token;

      if (jwt != null && jwt.isNotEmpty) {
        await _jwtSecureStorage.write(key: _jwtStorageKey, value: jwt);
        notifyListeners(); // Notify that auth state (JWT) has changed
        debugPrint("AuthService: Login successful. JWT stored.");
      } else {
        // Handle case where login is successful by API standards, but no token is returned
        debugPrint("AuthService: Login response received, but no JWT token in response.");
        throw Exception("Login failed: No token received from server.");
      }
    } catch (e) {
      debugPrint("AuthService: Login API call error: $e");
      // Optionally, clear any potentially stale JWT if login fails decisively
      // await _jwtSecureStorage.delete(key: _jwtStorageKey);
      // notifyListeners(); // if you clear the token
      rethrow; // Rethrow to allow UI or calling service to handle it
    }
  }

  Future<void> refreshToken() async {
    debugPrint("AuthService: Attempting to refresh token (by logging in again).");
    // login() already handles getting credentials from SettingsService
    // and calls notifyListeners on success.
    await login();
  }

  Future<void> logout() async {
    await _jwtSecureStorage.delete(key: _jwtStorageKey);
    notifyListeners();
    debugPrint("AuthService: Logged out (JWT deleted).");
  }
}