import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/api_factory.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/extensions/time.dart';
import 'package:mediasink_app/screens/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChannelDetailsScreen extends StatefulWidget {
  final int channelId;
  final String title;

  const ChannelDetailsScreen({super.key, required this.channelId, required this.title});

  @override
  _ChannelDetailsScreenState createState() => _ChannelDetailsScreenState();
}

class _ChannelDetailsScreenState extends State<ChannelDetailsScreen> {
  late Future<ServicesChannelInfo> _channelDetails;
  late String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _channelDetails = fetchChannelDetails(widget.channelId);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl');
  }

  Future<ServicesChannelInfo> fetchChannelDetails(int channelId) async {
    final apiClient = await ApiClientFactory().create();
    final response = await apiClient.get('/channels/$channelId');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ServicesChannelInfo.fromJson(data);
    } else {
      throw Exception('Failed to load channel details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      bottomNavigationBar: FutureBuilder(
        future: _channelDetails,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error');
          } else if (snapshot.hasData) {
            final channel = snapshot.data!;
            return BottomAppBar(
              height: 50,
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Text('Videos: ${channel.recordingsCount}', style: TextStyle(fontSize: 16, color: Colors.black87)),
                  Spacer(),
                  Text('Total size: ${channel.recordingsSize!.toGB()}', style: TextStyle(fontSize: 16, color: Colors.black87)), //
                ],
              ),
            );
          } else {
            return Text('No data');
          }
        },
      ),
      body: FutureBuilder<ServicesChannelInfo>(
        future: _channelDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final channel = data;
            final recordings = data.recordings;

            return (channel.recordingsCount == 0)
                ? Center(child: Text("No Videos", style: TextStyle(fontSize: 24)))
                : ListView(
                  children: [
                    // Display recordings with play buttons
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: recordings?.length,
                      itemBuilder: (context, index) {
                        final recording = recordings![index];

                        return Card(
                          margin: const EdgeInsets.all(6.0),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey.shade500, width: 1),
                            borderRadius: BorderRadius.circular(6), // Optional
                          ),
                          elevation: 4,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(title: channel.channelName!, videoUrl: '$_serverUrl/recordings/${recording.pathRelative}')));
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      child: CachedNetworkImage(
                                        imageUrl: '$_serverUrl/recordings/${recording.previewCover ?? channel.preview}',
                                        fit: BoxFit.cover,
                                        height: 180,
                                        width: double.infinity,
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
                                      ),
                                    ),
                                    const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
                                  ],
                                ),
                              ),
                              // Play button
                              Padding(
                                padding: EdgeInsets.fromLTRB(15, 0, 10, 0),
                                child: Row(
                                  children: [
                                    Text(recording.duration!.toHHMMSS()),
                                    SizedBox(width: 10),
                                    Text(recording.size!.toGB()),
                                    Spacer(), //
                                    IconButton(onPressed: () => {}, icon: Icon(Icons.download)),
                                    IconButton(onPressed: () => {}, icon: Icon(Icons.favorite, color: Colors.pink)),
                                    IconButton(onPressed: () => {}, icon: Icon(Icons.delete, color: Colors.red.shade700)),
                                  ], //
                                ),
                              ), //
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}
