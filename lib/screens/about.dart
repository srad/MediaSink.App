import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AboutScreen();
}

class _AboutScreen extends State<AboutScreen> {
  PackageInfo _packageInfo = PackageInfo(appName: 'Unknown', packageName: 'Unknown', version: 'Unknown', buildNumber: 'Unknown', buildSignature: 'Unknown', installerStore: 'Unknown');

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Widget _infoTile(String title, String subtitle) {
    return ListTile(title: Text(title), subtitle: Text(subtitle.isEmpty ? 'Not set' : subtitle));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PackageInfoPlus example'), elevation: 4),
      body: ListView(
        children: <Widget>[
          _infoTile('App name', _packageInfo.appName),
          _infoTile('Package name', _packageInfo.packageName),
          _infoTile('App version', _packageInfo.version),
          _infoTile('Build number', _packageInfo.buildNumber),
          //_infoTile('Build signature', _packageInfo.buildSignature),
          _infoTile('Installer store', _packageInfo.installerStore ?? 'not available'),
          // _infoTile(
          //   'Install time',
          //   _packageInfo.installTime?.toIso8601String() ??
          //       'Install time not available',
          // ),
          // _infoTile(
          //   'Update time',
          //   _packageInfo.updateTime?.toIso8601String() ??
          //       'Update time not available',
          // ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: ElevatedButton(style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 20, horizontal: 0)), backgroundColor: WidgetStateProperty.all(Colors.deepPurple), foregroundColor: WidgetStateProperty.all(Colors.white)), child: const Text("Check for update"), onPressed: () {})),
        ],
      ),
    );
  }
}
