import 'package:flutter/material.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/simple_http_client.dart';
import 'package:mediasink_app/widgets/video_list_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';

class VideosFilterScreen extends StatefulWidget {
  const VideosFilterScreen({super.key});

  @override
  State<VideosFilterScreen> createState() => _VideosFilterScreenState();
}

class _VideosFilterScreenState extends State<VideosFilterScreen> {
  late Future<List<Video>>? _futureVideos;
  String _sortBy = 'created_at';
  String _order = 'desc';
  int _limit = 25;
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
    final client = await SimpleHttpClientFactory.create();
    final response = await client.get('/recordings/filter/$_sortBy/$_order/$_limit');
    await _loadSettings();

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      final List<DatabaseRecording> recordings = data.map((dynamic i) => DatabaseRecording.fromJson(i as Map<String, dynamic>)).toList();

      return recordings
          .map(
            (recording) => Video(
              bookmark: recording.bookmark == true,
              channelName: recording.channelName,
              videoId: recording.recordingId!,
              duration: recording.duration!,
              size: recording.size!,
              createdAt: DateTime.parse(recording.createdAt!),
              previewCover: '$_serverUrl/recordings/${recording.previewCover ?? ''}',
              url: '$_serverUrl/recordings/${recording.pathRelative ?? ''}', //
            ),
          )
          .toList();
    }
    return [];
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
      appBar: AppBar(title: const Text("Filter Videos")),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: VideoListBuilder(
              futureVideos: _futureVideos,
              onRefresh: _refreshVideos, //
            ),
          ),
        ], //
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              isDense: true,
              decoration: const InputDecoration(labelText: 'Sort by', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: const [DropdownMenuItem(value: 'created_at', child: Text('Date')), DropdownMenuItem(value: 'size', child: Text('Size')), DropdownMenuItem(value: 'duration', child: Text('Duration'))],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                    _futureVideos = _fetchVideos();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _order,
              isDense: true,
              decoration: const InputDecoration(labelText: 'Order', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: const [DropdownMenuItem(value: 'asc', child: Text('Asc')), DropdownMenuItem(value: 'desc', child: Text('Desc'))],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _order = value;
                    _futureVideos = _fetchVideos();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _limit,
              isDense: true,
              decoration: const InputDecoration(labelText: 'Limit', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: const [25, 50, 100, 200, 500].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _limit = value;
                    _futureVideos = _fetchVideos();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
