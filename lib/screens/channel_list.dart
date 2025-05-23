import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/screens/channel_details.dart';
import 'package:mediasink_app/widgets/snack_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  _ChannelListScreenState createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final ValueNotifier<List<ServicesChannelInfo>> _channelsListNotifier = ValueNotifier([]);
  bool _isLoading = true;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) => _loadChannels());
  }

  Future _loadChannels() async {
    _isLoading = true;
    try {
      final channels = await fetchChannels();
      _channelsListNotifier.value = channels;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showError('$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('serverUrl');
    _serverUrl = '$url/recordings';
  }

  Future _refresh() async {
    await _loadChannels();
    if (mounted) ScaffoldMessenger.of(context).showOk('Reloaded');
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
      body: ValueListenableBuilder<List<ServicesChannelInfo>>(
        valueListenable: _channelsListNotifier,
        builder: (context, channels, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (channels.isEmpty) {
            return const Center(child: Text("No channels"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              itemCount: channels.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                childAspectRatio: 3/2,//
              ),
              itemBuilder: (context, index) {
                final channel = channels[index];
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
                                  child: Center(child: CircularProgressIndicator()), //
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: Icon(Icons.broken_image, size: 40)), //
                                ),
                            imageUrl: '$_serverUrl/${channel!.preview}' ?? '',
                            fit: BoxFit.cover,
                          ), //
                        ), //
                      ),

                      // Gradient overlay
                      Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)))),

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
        },
      ),
    );
  }
}
