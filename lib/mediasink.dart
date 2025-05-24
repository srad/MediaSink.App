import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mediasink_app/bootstrap.dart';
import 'package:mediasink_app/factories/rest_client_factory.dart';
import 'package:mediasink_app/screens/channel_details.dart';
import 'package:mediasink_app/screens/channel_form.dart';
import 'package:mediasink_app/screens/channel_list.dart';
import 'package:mediasink_app/screens/job_list.dart';
import 'package:mediasink_app/screens/splash.dart';
import 'package:mediasink_app/screens/streams_list.dart';
import 'package:mediasink_app/screens/About.dart';
import 'package:mediasink_app/screens/settings.dart';
import 'package:mediasink_app/screens/videos_bookmarked.dart';
import 'package:mediasink_app/screens/videos_filter.dart';
import 'package:mediasink_app/screens/videos_random.dart';
import 'package:mediasink_app/services/settings_service.dart';
import 'package:mediasink_app/services/token_manager.dart';
import 'package:mediasink_app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mediasink_app/l10n/app_localizations.dart';

class MediaSinkApp extends StatefulWidget {
  const MediaSinkApp({
    super.key,
    required this.isConfigured,
    required this.settingsService,
    required this.restClientFactory,
    required this.dio,
    required this.tokenManager, //
  });

  final bool isConfigured;
  final SettingsService settingsService;
  final RestClientFactory restClientFactory;
  final Dio dio;
  final TokenManager tokenManager;

  @override
  State<StatefulWidget> createState() => _MediaSinkApp();
}

class _MediaSinkApp extends State<MediaSinkApp> {
  FullBootstrapServices? _bootstrapServices;

  void _rebootApp() async {
    final services = await fullBootstrap(widget.settingsService);
    setState(() {
      _bootstrapServices = services;
    });
  }

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();

    if (!widget.isConfigured  && _bootstrapServices == null) {
      final themeProvider = context.watch<ThemeProvider>();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: widget.settingsService),
          Provider.value(value: widget.dio),
          Provider.value(value: widget.tokenManager),
          Provider.value(value: widget.restClientFactory), //
        ],
        child: MaterialApp(
            home: SettingsScreen(onSettingsSaved: _rebootApp),
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
        ),
      );
    } else {
      final services = _bootstrapServices;
      if (services == null) {
        return FutureBuilder<FullBootstrapServices>(
          future: fullBootstrap(widget.settingsService),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const MaterialApp(home: SplashScreen());
            }

            final themeProvider = context.watch<ThemeProvider>();
            final services = snapshot.data!;

            return _buildAppWithServices(themeProvider, services);
          },
        );
      } else {
        final themeProvider = context.watch<ThemeProvider>();
        return _buildAppWithServices(themeProvider, services);
      }
    }
  }

  Widget _buildAppWithServices(ThemeProvider themeProvider, FullBootstrapServices services) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: services.settingsService),
        Provider.value(value: services.dio),
        Provider.value(value: services.tokenManager),
        Provider.value(value: services.restClientFactory),
        Provider.value(value: services.restClient),
        ChangeNotifierProvider.value(value: services.authService),
        ChangeNotifierProvider.value(value: services.webSocketService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), //
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = context.watch<ThemeProvider>();

          return MaterialApp(
            title: S.of(context)?.appTitle ?? 'MediaSink',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const StreamsListScreen(),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate, //
            ],
            routes: {
              '/streams': (context) => StreamsListScreen(),
              '/channels': (context) => ChannelListScreen(),
              '/channel': (context) => ChannelDetailsScreen(channelId: ModalRoute.of(context)!.settings.arguments as int, title: ModalRoute.of(context)!.settings.arguments as String),
              '/channelForm': (context) => const ChannelFormScreen(),
              '/filter': (context) => const VideosFilterScreen(),
              '/bookmarked': (context) => const VideosBookmarkedScreen(),
              '/random': (context) => const VideosRandomScreen(),
              '/jobs': (context) => const JobScreen(),
              '/settings': (context) => SettingsScreen(),
              '/about': (context) => AboutScreen(), //
            },
          );
        },
      ),
    );
  }
}
