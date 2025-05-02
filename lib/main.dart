import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mediasink_app/screens/channel_details.dart';
import 'package:mediasink_app/screens/channels_list.dart';
import 'package:mediasink_app/screens/startup.dart';
import 'package:mediasink_app/screens/About.dart';
import 'package:mediasink_app/screens/settings.dart';
import 'package:mediasink_app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:fvp/fvp.dart' as fvp;

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  fvp.registerWith(
    options: {
      'platforms': ['android', 'ios'],
    },
  ); // only these platforms will use this plugin implementation
  runApp(ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MediaSinkApp()));
  // FlutterNativeSplash.remove();
}

class MediaSinkApp extends StatefulWidget {
  const MediaSinkApp({super.key});

  @override
  State<StatefulWidget> createState() => _MediaSinkApp();
}

class _MediaSinkApp extends State<MediaSinkApp> {
  final lightTheme = ThemeData(brightness: Brightness.light, primaryColor: Colors.purple, appBarTheme: AppBarTheme(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white));
  final darkTheme = ThemeData(brightness: Brightness.dark, primaryColor: Colors.purple, appBarTheme: AppBarTheme(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white));

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'MediaSink',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const StartupScreen(),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/channels': (context) => ChannelListScreen(),
        '/channel': (context) => ChannelDetailsScreen(channelId: ModalRoute.of(context)!.settings.arguments as int, title: ModalRoute.of(context)!.settings.arguments as String),
        // '/channel': (context) {
        //   final videoId = ModalRoute.of(context)!.settings.arguments as int;
        //   return ChannelScreen(videoId: videoId);
        // },
        // '/add': (context) => AddChannelScreen(),
        // '/video': (context) {
        //   final videoId = ModalRoute.of(context)!.settings.arguments as int;
        //   return VideoScreen(videoId: videoId);
        // },
        // '/filter': (context) => FilterScreen(),
        '/settings': (context) => SettingsScreen(),
        '/about': (context) => AboutScreen(),
      },
    );
  }
}
