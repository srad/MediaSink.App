import 'package:flutter/material.dart';
import 'package:mediasink_app/models/video.dart';
import 'package:mediasink_app/screens/channel_details.dart';
import 'package:mediasink_app/screens/video_player.dart';
import 'video_card.dart';

class VideoListBuilder extends StatelessWidget {
  final ValueNotifier<List<Video>> videoListNotifier;
  bool isLoading;

  final VoidCallback onRefresh;

  final void Function(Video)? onBookmarked;
  final void Function(Video)? onDeleted;
  final void Function(Video, String)? onError;
  final void Function(Video)? onTapVideo;

  VideoListBuilder({
    super.key,
    required this.videoListNotifier,
    required this.onRefresh,
    this.onBookmarked,
    this.onDeleted,
    this.onError,
    this.onTapVideo,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Video>>(
      valueListenable: videoListNotifier,
      builder: (context, videos, _) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (videos.isEmpty) {
          return const Center(child: Text("No videos found"));
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            itemCount: videos.length,
            separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 0),
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoCard(
                key: key,
                video: video,
                showChannelLink: true,
                onBookmarked: _toggleBookmark,
                onDeleted: _deleteVideo,
                onError: onError,
                onParent: (p0) {
                  if (p0.channelId != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelDetailsScreen(channelId: p0.channelId!, title: "Channel Videos")));
                  }
                },
                onTapVideo: () {
                  if (onTapVideo != null) {
                    onTapVideo!(video);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          title: video.filename,
                          videoUrl: video.url,
                        ),
                      ),
                    );
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

  void _deleteVideo(Video video) {
    final updated = List<Video>.from(videoListNotifier.value)..removeWhere((v) => v.videoId == video.videoId);
    videoListNotifier.value = updated;
    if (onDeleted != null) onDeleted!(video);
  }

  void _toggleBookmark(Video video) {
    final copy = List<Video>.from(videoListNotifier.value);
    final index = copy.indexWhere((v) => v.videoId == video.videoId);
    if (index != -1) {
      copy[index] = video.copyWith(bookmark: !video.bookmark);
      videoListNotifier.value = copy;
      if (onBookmarked != null) onBookmarked!(video);
    }
  }
}
