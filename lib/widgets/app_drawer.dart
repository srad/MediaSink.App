import 'package:flutter/material.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  ListTile _tile(String label, String path, IconData icon) {
    return ListTile(
      title: Text(label),
      leading: Icon(icon),
      onTap: () {
        Navigator.pushNamed(context, path);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurpleAccent),
            child: Text('MediaSink', style: TextStyle(fontSize: 26)),
          ),
          _tile('Channels', '/channels', Icons.list),
          _tile('Settings', '/settings', Icons.settings),
          _tile('About', '/about', Icons.info),
        ],
      ),
    );
  }
}