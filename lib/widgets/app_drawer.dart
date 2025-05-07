import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/widgets/snack_utils.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Timer? _timer;
  double percent = 0;
  double usedGB = 0.0;
  double totalGB = 1.0; // Avoid division by zero

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _fetchStorage();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure that _fetchStorage is called only once when dependencies are ready
    _fetchStorage();
  }

  Future<void> _fetchStorage() async {
    try {
      final client = await RestClientFactory.create();
      final response = await client.info.getInfoDisk();

      // Only update state if the widget is still in the widget tree
      if (mounted) {
        setState(() {
          usedGB = response.usedFormattedGb?.toDouble() ?? 0;
          totalGB = response.sizeFormattedGb?.toDouble() ?? 1;
          percent = usedGB / totalGB;
        });
      }
    } catch (e) {
      if (mounted) {
        // Access ScaffoldMessenger of the context to show error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ListTile _tile(String label, String path, IconData icon) {
    return ListTile(
      title: Text(label),
      leading: Icon(icon),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        Navigator.pushNamed(context, path);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color.alphaBlend(Colors.white.withOpacity(0.1), Theme.of(context).primaryColor);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: color),
            child: Row(
              children: [
                const Text('MediaSink App', style: TextStyle(fontSize: 28, color: Colors.white)),
                const Spacer(),
                SizedBox(height: 40, width: 40, child: Image.asset('assets/icon.png')),
              ],
            ),
          ),
          _tile('Streams', '/streams', Icons.videocam_rounded),
          _tile('Channels', '/channels', Icons.grid_view_rounded),
          _tile('Query Videos', '/filter', Icons.query_builder),
          _tile('Favourites', '/bookmarked', Icons.favorite_rounded),
          _tile('Random Videos', '/random', Icons.question_mark),
          _tile('Settings', '/settings', Icons.settings),
          _tile('About', '/about', Icons.info),
          Divider(height: 10),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: 20),
            child: CircularPercentIndicator(
              radius: 50.0,
              lineWidth: 11.0,
              percent: percent,
              center: Text('${(percent * 100).toStringAsFixed(1)}%'),
              progressColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey[300]!,
              footer: Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Text('Used: ${usedGB.toStringAsFixed(0)} GB / ${totalGB.toStringAsFixed(0)} GB'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
