import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreen();
}

class _StartupScreen extends State<StartupScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _checkCredentials();
  }

  Future<void> _checkCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('serverUrl') ?? '';
    final username = await _secureStorage.read(key: 'server_username') ?? '';
    final password = await _secureStorage.read(key: 'server_password') ?? '';

    final credentialsValid = serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

    await Future.delayed(const Duration(milliseconds: 500)); // optional splash delay

    if (credentialsValid) {
      Navigator.of(context).pushReplacementNamed('/streams');
    } else {
      Navigator.of(context).pushReplacementNamed('/settings', arguments: 'Please enter server URL, username and password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
