import 'package:flutter/material.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/widgets/video_list_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';

class VideosBookmarkedScreen extends StatefulWidget {
  const VideosBookmarkedScreen({super.key});

  @override
  State<VideosBookmarkedScreen> createState() => _VideosBookmarkedScreenState();
}

class _VideosBookmarkedScreenState extends State<VideosBookmarkedScreen> {
  late Future<List<Video>>? _futureVideos;
  late String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _futureVideos = _fetchVideos();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl');
  }

  Future<List<Video>> _fetchVideos() async {
    final client = await RestClientFactory.create();
    final recordings = await client.recordings.getRecordingsBookmarks();
    await _loadSettings();

    return recordings
        .map(
          (recording) => Video(
            channelName: recording.channelName,
            videoId: recording.recordingId!,
            duration: recording.duration!,
            bookmark: recording.bookmark == true,
            size: recording.size!,
            createdAt: DateTime.parse(recording.createdAt!),
            previewCover: '$_serverUrl/recordings/${recording.previewCover ?? ''}',
            //
            url: '$_serverUrl/recordings/${recording.pathRelative ?? ''}',
          ),
        )
        .toList();
  }

  Future<void> _refreshVideos() async {
    final newFuture = _fetchVideos();
    setState(() {
      _futureVideos = newFuture;
    });
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorite Videos")),
      body: VideoListBuilder(
        futureVideos: _futureVideos,
        onRefresh: _refreshVideos, //
      ),
    );
  }
}
