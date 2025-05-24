import 'package:flutter/material.dart';
import 'package:mediasink_app/extensions/color.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadTheme(); // Load theme when the app starts
  }

  ThemeMode get themeMode => _themeMode;

  final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: '#322448'.toColor(), //
    appBarTheme: AppBarTheme(backgroundColor: '#322448'.toColor(), foregroundColor: Colors.white),
    bottomAppBarTheme: BottomAppBarTheme(
      color: Colors.grey.shade200, // Light mode BottomAppBar color
    ),
  );
  final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: '#322448'.toColor(), //
    appBarTheme: AppBarTheme(backgroundColor: '#322448'.toColor(), foregroundColor: Colors.white),
  );

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveTheme(); // Save preference
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }
}
