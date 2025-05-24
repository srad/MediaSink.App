import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mediasink_app/services/auth_service.dart';
import 'package:mediasink_app/services/settings_service.dart';

class WebSocketService extends ChangeNotifier {
  final SettingsService _settingsService;
  final AuthService _authService;

  WebSocketChannel? _channel;
  String? _baseUrl;

  final _messageController = StreamController<Map>.broadcast();
  final _authStatusController = StreamController<bool>.broadcast();

  bool _connected = false;
  bool _authenticated = false;

  WebSocketService(this._settingsService, this._authService);

  Stream<dynamic> get messages => _messageController.stream;

  Stream<bool> get authStatus => _authStatusController.stream;

  bool get isConnected => _connected;

  bool get isAuthenticated => _authenticated;

  void updateBaseUrl(String url) => _baseUrl = url;

  Future<void> connect({bool reconnect = false}) async {
    if (_connected && !reconnect) return;

    try {
      _baseUrl ??= await _settingsService.getWebSocketBaseUrl();
      if (_baseUrl == null) {
        _messageController.addError(Exception("WebSocket base URL missing"));
        return;
      }

      // Attempt login if not already logged in
      await _authService.login();
      final token = await _authService.getCurrentJwt();

      if (token == null) {
        _authStatusController.add(false);
        _messageController.addError(Exception("JWT token missing after login"));
        return;
      }

      await disconnect(); // Clean up any previous connection

      final uri = Uri.parse('$_baseUrl/api/v1/ws?Authorization=$token');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      _authenticated = false;
      notifyListeners();

      _channel!.stream.listen(_handleMessage, onDone: _handleDisconnect, onError: _handleError);
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final message = jsonDecode(raw);
      _authenticated = true;
      _authStatusController.add(true);
      _messageController.add(message);
      notifyListeners();
    } catch (_) {
      log("WebSocketService: Invalid message received: $raw");
    }
  }

  void _handleError(dynamic error) {
    _connected = false;
    _authenticated = false;
    _authStatusController.add(false);
    _messageController.addError(error);
    notifyListeners();
  }

  void _handleDisconnect() => _handleError(Exception("WebSocket disconnected"));

  void sendMessage(dynamic message) {
    if (_connected && _authenticated && _channel?.closeCode == null) {
      _channel!.sink.add(message);
    } else {
      debugPrint("WebSocketService: Cannot send. Not ready.");
    }
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _connected = false;
    _authenticated = false;
    _authStatusController.add(false);
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _authStatusController.close();
    super.dispose();
  }
}
