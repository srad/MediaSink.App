import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/factories/rest_client_factory.dart';
import 'package:mediasink_app/services/settings_service.dart';
import 'package:mediasink_app/utils/permission_utils.dart';
import 'package:mediasink_app/utils/utils.dart';
import 'package:mediasink_app/widgets/app_drawer.dart';
import 'package:mediasink_app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ServerState { valid, invalid, unchecked }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onSettingsSaved});
  final VoidCallback? onSettingsSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _wsServerUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? get serverUrl => _serverUrlController.text.trim();

  ServerState _serverState = ServerState.unchecked;
  bool _isSaving = false;
  bool _formValid = false;

  bool _darkMode = false;
  bool _notificationsEnabled = false;

  bool _saved = false;
  bool _settingsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_settingsLoaded) {
      _settingsLoaded = true;
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final settingsService = Provider.of<SettingsService>(context);

    final serverUrl = await settingsService.getServerUrl();
    final wsServerUlr = await settingsService.getWebSocketBaseUrl();
    final username = await settingsService.getUsername();
    final password = await settingsService.getPassword();
    final isDarkMode = await settingsService.isDarkModeEnabled() ?? false;
    final areNotificationsEnabled = await settingsService.areNotificationsEnabled() ?? false;

    setState(() {
      _serverUrlController.text = serverUrl ?? '';
      _wsServerUrlController.text = wsServerUlr ?? '';
      _usernameController.text = username ?? '';
      _passwordController.text = password ?? '';
      _darkMode = isDarkMode;
      _notificationsEnabled = areNotificationsEnabled;
    });
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _isSaving = true);
      setState(() {
        _serverState = ServerState.unchecked;
      });
      if (!_formKey.currentState!.validate()) return;
      final exists = await checkServerAvailable(Uri.parse(serverUrl!));

      setState(() {
        _serverState = exists ? ServerState.valid : ServerState.invalid;
      });

      if (_serverState != ServerState.valid) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server is unreachable, not saved ❌')));
        return;
      }

      try {
        if (mounted) {
          final settingsService = Provider.of<SettingsService>(context, listen: false);
          await settingsService.saveServerUrl(_serverUrlController.text.trim());
          await settingsService.saveWebSocketBaseUrl(_wsServerUrlController.text.trim());
          await settingsService.saveDarkMode(_darkMode);
          await settingsService.saveNotificationsEnabled(_notificationsEnabled);

          final factory = Provider.of<RestClientFactory>(context, listen: false);
          final client = await factory.create();

          // Save settings and try a login request:
          final auth = RequestsAuthenticationRequest(username: _usernameController.text.trim(), password: _passwordController.text);
          await client.auth.postAuthLogin(authenticationRequest: auth);

          await settingsService.saveUsername(_usernameController.text.trim());
          await settingsService.savePassword(_passwordController.text);
        }

        setState(() {
          _saved = true;
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved ✅')));

        if (widget.onSettingsSaved != null) {
          widget.onSettingsSaved!();
        }
      } on DioException catch (dioError) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid connection data, is the server IP, port and credentials correct? ❌')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credentils invalid ❌')));
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text(e.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        final settingsService = Provider.of<SettingsService>(context, listen: false);
        await settingsService.deleteServerUrl();
        await settingsService.deleteWebSocketUrl();
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _validateForm() {
    setState(() {
      _formValid = _formKey.currentState?.validate() ?? false;
    });
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return 'Server URL is required';
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.isAbsolute) return 'Invalid URL';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: _saved ? AppDrawer() : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          onChanged: _validateForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Server Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(controller: _serverUrlController, decoration: const InputDecoration(labelText: 'Server URL'), validator: _validateUrl),
              TextFormField(controller: _wsServerUrlController, decoration: const InputDecoration(labelText: 'WS Server URL'), validator: _validateUrl),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username'), validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (val) => val == null || val.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _formValid && !_isSaving ? _saveSettings : null, child: _isSaving ? Container(height: 10, width: 10, child: CircularProgressIndicator()) : const Text('Save Settings')),
              const Divider(height: 30),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  themeProvider.toggleTheme();
                },
              ),
              SwitchListTile(
                title: const Text('Enable Notifications'),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    final allowed = await PermissionUtils.requestNotificationPermissions();
                    if (allowed) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notificationsEnabled', value);
                    }
                  }
                  setState(() => _notificationsEnabled = value);
                },
              ), //
            ],
          ),
        ),
      ),
    );
  }
}
