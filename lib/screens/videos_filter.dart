import 'package:flutter/material.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/simple_http_client.dart';
import 'package:mediasink_app/widgets/video_card.dart';
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
  int _limit = 20;
  late String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _futureVideos = _fetchVideos();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl');
  }

  Future<List<Video>> _fetchVideos() async {
    final client = await SimpleHttpClientFactory.create();
    final response = await client.get('/recordings/filter/$_sortBy/$_order/$_limit');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      final List<DatabaseRecording> recordings = data.map((dynamic i) => DatabaseRecording.fromJson(i as Map<String, dynamic>)).toList();

      return recordings
          .map(
            (recording) => Video(
              videoId: recording.recordingId!,
              duration: recording.duration!,
              size: recording.size!,
              createdAt: DateTime.parse(recording.createdAt!),
              previewCover: '$_serverUrl/recordings/${recording.previewCover ?? ''}', //, //
            ),
          )
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Grid")),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<Video>>(
              future: _futureVideos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No videos found"));
                }

                final videos = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return VideoCard(video: video, onBookmark: (p0) => {}, onDelete: (p0) => {}, onTapVideo: () => {}, payload: video, showDownload: false);
                  },
                );
              },
            ),
          ),
        ],
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
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'created_at', child: Text('Date')),
                DropdownMenuItem(value: 'size', child: Text('Size')),
                DropdownMenuItem(value: 'duration', child: Text('Duration')),
              ],
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
              decoration: const InputDecoration(
                labelText: 'Order',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'asc', child: Text('Asc')),
                DropdownMenuItem(value: 'desc', child: Text('Desc')),
              ],
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
              decoration: const InputDecoration(
                labelText: 'Limit',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: const [10, 20, 50, 100]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
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
