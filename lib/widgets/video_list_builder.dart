import 'package:flutter/material.dart';
import 'package:mediasink_app/models/video.dart';
import 'package:mediasink_app/screens/video_player.dart';
import 'video_card.dart';

class VideoListBuilder extends StatelessWidget {
  final Future<List<Video>>? futureVideos;
  final void Function(Video video)? onTapVideo;
  final Function onRefresh;

  const VideoListBuilder({
    super.key,
    required this.futureVideos,
    required this.onRefresh,
    this.onTapVideo, //
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Video>>(
      future: futureVideos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No videos found"));
        }

        final videos = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () => onRefresh(),
          child: ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoCard(
                video: video,
                onBookmark: (_) => {},
                onDelete: (_) => {},
                onTapVideo: () {
                  if (onTapVideo != null) {
                    onTapVideo!(video);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(title: video.channelName ?? 'Video', videoUrl: video.url!)));
                  }
                },
                payload: video,
                showDownload: true,
              );
            },
          ),
        );
      },
    );
  }
}
