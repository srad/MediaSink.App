import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();

  static const String _serverUrlKey = 'server_url';
  static const String _wsBaseUrlKey = 'ws_url';
  static const String _serverUsernameKey = 'server_username';
  static const String _serverPasswordKey = 'server_password';
  static const String _darkModeKey = 'dark_mode';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  String? _serverUrl;
  String? _websocketBaseUrl;
  String? _username;
  bool _darkModeEnabled = false;
  bool _isLoading = true;

  String? get serverUrl => _serverUrl;
  String? get websocketBaseUrl => _websocketBaseUrl;
  String? get username => _username;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get isLoading => _isLoading;

  SettingsService() {
    _isLoading = true;
    notifyListeners();
    loadSettings();
  }

  SettingsService._();

  static Future<SettingsService> create() async {
    final service = SettingsService._();
    await service.loadSettings();
    return service;
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _serverUrl = await _secureStorage.read(key: _serverUrlKey);
    _websocketBaseUrl = await _secureStorage.read(key: _wsBaseUrlKey);
    _username = await _secureStorage.read(key: _serverUsernameKey);
    final darkModeString = await _secureStorage.read(key: _darkModeKey);
    _darkModeEnabled = darkModeString == 'true';

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveServerUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _secureStorage.delete(key: _serverUrlKey);
      _serverUrl = null;
    } else {
      await _secureStorage.write(key: _serverUrlKey, value: url);
      _serverUrl = url;
    }
    notifyListeners();
  }

  Future<void> saveWebSocketBaseUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _secureStorage.delete(key: _wsBaseUrlKey);
      _websocketBaseUrl = null;
    } else {
      await _secureStorage.write(key: _wsBaseUrlKey, value: url);
      _websocketBaseUrl = url;
    }
    notifyListeners();
  }

  Future<void> saveUsername(String? username) async {
    if (username == null || username.isEmpty) {
      await _secureStorage.delete(key: _serverUsernameKey);
      _username = null;
    } else {
      await _secureStorage.write(key: _serverUsernameKey, value: username);
      _username = username;
    }
    notifyListeners();
  }

  Future<void> savePassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _secureStorage.delete(key: _serverPasswordKey);
    } else {
      await _secureStorage.write(key: _serverPasswordKey, value: password);
    }
    // No notifyListeners for password save by default for security UI reasons.
  }

  Future<void> saveDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_darkModeKey, enabled);
    _darkModeEnabled = enabled;
    notifyListeners();
  }

  Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool(_darkModeKey);
    return result ?? false;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_notificationsEnabledKey, enabled);
    notifyListeners();
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool(_notificationsEnabledKey);
    return result ?? false;
  }

  Future<String?> getServerUrl() async {
    return _serverUrl ?? await _secureStorage.read(key: _serverUrlKey);
  }

  Future<String?> getWebSocketBaseUrl() async {
    return _websocketBaseUrl ?? await _secureStorage.read(key: _wsBaseUrlKey);
  }

  Future<String?> getUsername() async {
    return _username ?? await _secureStorage.read(key: _serverUsernameKey);
  }

  Future<String?> getPassword() async {
    return await _secureStorage.read(key: _serverPasswordKey);
  }

  Future<(String, String)?> getAuthCredentials() async {
    final username = await getUsername();
    final password = await getPassword();
    if (username != null && password != null) {
      return (username, password);
    }
    return null;
  }

  Future<void> saveConnectionSettings({
    required String? serverUrl,
    required String? wsUrl,
    required String? username,
    required String? password,
  }) async {
    await saveServerUrl(serverUrl);
    await saveWebSocketBaseUrl(wsUrl);
    await saveUsername(username);
    if (password != null && password.isNotEmpty) {
      await savePassword(password);
    }
  }

  Future<bool> areCoreServicesConfigured() async {
    final httpUrl = await getServerUrl();
    final wsUrlVal = await getWebSocketBaseUrl();
    final user = await getUsername();
    // final pass = await getPassword(); // Password check might be optional for "configured" status
    // depending on whether it can be empty.
    return httpUrl != null && httpUrl.isNotEmpty &&
        wsUrlVal != null && wsUrlVal.isNotEmpty &&
        user != null && user.isNotEmpty;
    // && pass != null && pass.isNotEmpty; // Add if password must exist
  }

  Future<void> deleteServerUrl() async {
    await _secureStorage.delete(key: _serverUrlKey);
    _serverUrl = null;
    notifyListeners();
  }

  Future<void> deleteWebSocketUrl() async {
    await _secureStorage.delete(key: _wsBaseUrlKey);
    _websocketBaseUrl = null;
    notifyListeners();
  }
}