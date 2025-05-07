import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/screens/channel_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  _ChannelListScreenState createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  late Future<List<ServicesChannelInfo>> _futureChannels;
  late List<ServicesChannelInfo> _channels;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _futureChannels = fetchChannels();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('serverUrl');
    _serverUrl = '$url/recordings';
  }

  Future<List<ServicesChannelInfo>> fetchChannels() async {
    final client = await RestClientFactory.create();
    final response = await client.channels.getChannels();
    response.sort((a, b) => a.displayName!.compareTo(b.displayName!));
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Channels')),
      body: FutureBuilder(
        future: _futureChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _channels = snapshot.data ?? [];

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _futureChannels = fetchChannels();
                });
                try {
                  _channels = await _futureChannels;
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reloaded'), duration: Duration(seconds: 1)));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refresh failed: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: GridView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _channels.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 16 / 9),
                itemBuilder: (context, index) {
                  final channel = _channels[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelDetailsScreen(channelId: channel.channelId!, title: channel.channelName!))),
                    child: Stack(
                      children: [
                        // Preview image
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              placeholder:
                                  (context, url) => const SizedBox(
                                    height: 180,
                                    child: Center(child: CircularProgressIndicator()), //
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: const Center(child: Icon(Icons.broken_image, size: 40)), //
                                  ),
                              imageUrl: '$_serverUrl/${channel!.preview}' ?? '',
                              fit: BoxFit.cover,
                            ), //
                          ), //
                        ),

                        // Gradient overlay
                        Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)))),

                        // Channel info overlay
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(channel.displayName ?? 'No name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Row(
                                children: [
                                  if (channel.fav == true) Icon(Icons.favorite, color: Colors.pink, size: 16),
                                  if (channel.isOnline == true) Icon(Icons.circle, color: Colors.green, size: 12),
                                  if (channel.isPaused == true) Icon(Icons.pause_circle_filled, color: Colors.orange, size: 16),
                                  if (channel.isRecording == true) Icon(Icons.fiber_manual_record, color: Colors.red, size: 16), //
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          return Center(child: Text('No data'));
        },
      ),
    );
  }
}
