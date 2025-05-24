import 'package:flutter/material.dart';
import 'package:mediasink_app/extensions/color.dart';
import 'package:mediasink_app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: '#322448'.toColor(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 200, width: 200, child: Image.asset('assets/icon.png', filterQuality: FilterQuality.high)),
            SizedBox(height: 16), //
            Text('MediaSink is starting...', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 25, color: themeProvider.themeMode != ThemeMode.dark ? Colors.white : Colors.black)),
            SizedBox(height: 24),
            CircularProgressIndicator(), //
          ],
        ),
      ),
    );
  }
}
