import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mediasink_app/bootstrap.dart';
import 'package:mediasink_app/mediasink.dart';
import 'package:mediasink_app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:fvp/fvp.dart' as fvp;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight, //
  ]);

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  fvp.registerWith(
    options: {
      'platforms': ['android', 'ios'],
    },
  ); // only these platforms will use this plugin implementation

  await FlutterDownloader.initialize(
    debug: false, // optional: set to false to disable printing logs to console (default: true)
    ignoreSsl: true, // option: set to false to disable working with http links (default: false)
  );

  //debugPaintSizeEnabled = false;
  final bootstrap = await minimalBootstrap();
  final isConfigured = await bootstrap.settingsService.areCoreServicesConfigured();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), //
      ],
      child: MediaSinkApp(
        settingsService: bootstrap.settingsService,
        isConfigured: isConfigured,
        dio: bootstrap.dio,
        restClientFactory: bootstrap.restClientFactory,
        tokenManager: bootstrap.tokenManager, //
      ),
    ),
  );
  // FlutterNativeSplash.remove();
}
