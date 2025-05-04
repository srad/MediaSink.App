import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/extensions/recording.dart';
import 'package:mediasink_app/extensions/time.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/screens/video_player.dart';
import 'package:mediasink_app/widgets/confirm_dialog.dart';
import 'package:mediasink_app/widgets/messages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  ServicesChannelInfo? _channel;

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
    final api = await RestClientFactory.create();
    final channel = await api.channels.getChannelsId(id: channelId);
    channel.recordings?.sort((a, b) => DateTime.parse(b.createdAt!).compareTo(DateTime.parse(a.createdAt!)));
    return channel;
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
            if (channel.recordingsCount == 0) return SizedBox.shrink();
            return BottomAppBar(
              height: 70,
              child: Row(
                children: [
                  Chip(label: Text('Videos: ${channel.recordingsCount}')),
                  Spacer(),
                  Chip(label: Text('Total size: ${channel.recordingsSize!.toGB()}')), //
                ],
              ),
            );
          } else {
            return SizedBox.shrink();
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
            _channel = data;

            return (_channel!.recordingsCount == 0)
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 260, width: 260, child: Image.asset('assets/cat3.png', filterQuality: FilterQuality.high)),
                      Text('Empty', style: TextStyle(fontSize: 24)), //
                    ],
                  ),
                )
                : ListView(
                  children: [
                    // Display recordings with play buttons
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _channel!.recordings?.length,
                      itemBuilder: (context, index) {
                        final recording = _channel!.recordings?[index];

                        return Card(
                          margin: const EdgeInsets.all(6.0),
                          elevation: 4,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(title: _channel!.channelName!, videoUrl: '$_serverUrl/recordings/${recording!.pathRelative}')));
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      child: CachedNetworkImage(
                                        imageUrl: '$_serverUrl/recordings/${recording?.previewCover ?? _channel!.preview}',
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
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    Text(recording!.duration!.toHHMMSS()),
                                    const SizedBox(width: 15),
                                    Text(recording.size!.toGB()),
                                    const SizedBox(width: 15),
                                    Text('${timeago.format(DateTime.parse(recording.createdAt!), locale: 'en_short')} ago'),
                                    const Spacer(),
                                    IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, onPressed: () => {}, icon: Icon(Icons.download_rounded)),
                                    IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, onPressed: () => bookmark(recording), icon: Icon(recording.bookmark == true ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: recording.bookmark == true ? Colors.pink : null)),
                                    IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, onPressed: () => delete(recording), icon: Icon(Icons.delete_rounded, color: Colors.red.shade400)),
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

  Future<void> bookmark(DatabaseRecording recording) async {
    try {
      final client = await RestClientFactory.create();
      if (recording.bookmark == true) {
        await client.recordings.patchRecordingsIdUnfav(id: recording.recordingId!);
      } else {
        await client.recordings.patchRecordingsIdFav(id: recording.recordingId!);
      }
      setState(() {
        final index = _channel!.recordings?.indexWhere((rec) => rec.recordingId == recording.recordingId);
        if (index != -1) {
          // Use the original copyWith extension
          _channel!.recordings?[index!] = recording.copyWith(bookmark: !recording.bookmark!);
        }
      });
      if (mounted) snackOk(context, const Text('Saved'));
    } catch (e) {
      if (mounted) snackErr(context, Text(e.toString()));
    }
  }

  Future<void> delete(DatabaseRecording recording) async {
    try {
      confirm(
        context: context,
        title: const Text("Confirm"),
        content: const Text('Do you want to delete the file?'), //
        onConfirm: () async {
          final client = await RestClientFactory.create();
          await client.recordings.deleteRecordingsId(id: recording.recordingId!);
          setState(() {
            _channel!.recordings?.removeWhere((rec) => rec.recordingId == recording.recordingId);
          });
          if (mounted) snackOk(context, const Text('Deleted'));
        },
      );
    } catch (e) {
      if (mounted) snackErr(context, Text(e.toString()));
    }
  }
}
