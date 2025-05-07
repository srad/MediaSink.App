import 'package:flutter/material.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/widgets/snack_utils.dart';
import 'package:mediasink_app/widgets/video_list_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';

class VideosBookmarkedScreen extends StatefulWidget {
  const VideosBookmarkedScreen({super.key});

  @override
  State<VideosBookmarkedScreen> createState() => _VideosBookmarkedScreenState();
}

class _VideosBookmarkedScreenState extends State<VideosBookmarkedScreen> {
  final ValueNotifier<List<Video>> _videoListNotifier = ValueNotifier([]);
  bool _isLoading = true;

  late String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) => _loadVideos());
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await _fetchVideos();
      _videoListNotifier.value = videos;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showError('$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl');
  }

  Future<List<Video>> _fetchVideos() async {
    final client = await RestClientFactory.create();
    final recordings = await client.recordings.getRecordingsBookmarks();

    return recordings
        .map(
          (recording) => Video(
            videoId: recording.recordingId!,
            duration: recording.duration!,
            bookmark: recording.bookmark == true,
            size: recording.size!,
            createdAt: DateTime.parse(recording.createdAt!),
            previewCover: '$_serverUrl/recordings/${recording.previewCover}',
            url: '$_serverUrl/recordings/${recording.pathRelative}',
            filename: recording.filename, //
          ),
        )
        .toList();
  }

  Future _refreshVideos() async {
    await _loadVideos();
    if (mounted) ScaffoldMessenger.of(context).showOk('Reloaded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorite Videos")),
      body: VideoListBuilder(
        isLoading: _isLoading,
        videoListNotifier: _videoListNotifier,
        onRefresh: _refreshVideos, //
      ),
    );
  }
}
