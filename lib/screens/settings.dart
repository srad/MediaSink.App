import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediasink_app/utils/permission_utils.dart';
import 'package:mediasink_app/utils/utils.dart';
import 'package:mediasink_app/widgets/app_drawer.dart';
import 'package:mediasink_app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ServerState { valid, invalid, unchecked }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? get serverUrl => _serverUrlController.text.trim();

  final _secureStorage = const FlutterSecureStorage();

  ServerState _serverState = ServerState.unchecked;
  bool _isSaving = false;
  bool _formValid = false;

  bool _darkMode = false;
  bool _notificationsEnabled = false;

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('serverUrl') ?? '';
    final username = await _secureStorage.read(key: 'server_username') ?? '';
    final password = await _secureStorage.read(key: 'server_password') ?? '';
    setState(() {
      _serverUrlController.text = serverUrl;
      _usernameController.text = username;
      _passwordController.text = password;
      _darkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      _saved = username != null && username.isNotEmpty && password != null && password.isNotEmpty;
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

      final snackBar = SnackBar(content: Text(_serverState == ServerState.valid ? 'Server is reachable, saved ✅' : 'Server is unreachable, not saved ❌'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      if (_serverState != ServerState.valid) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('serverUrl', _serverUrlController.text.trim());
      await prefs.setBool('darkMode', _darkMode);

      await _secureStorage.write(key: 'server_username', value: _usernameController.text.trim());
      await _secureStorage.write(key: 'server_password', value: _passwordController.text);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
      _saved = true;
    } catch (e) {
      final snackBar = SnackBar(content: Text(e.toString()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
    final themeProvider = Provider.of<ThemeProvider>(context);

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
