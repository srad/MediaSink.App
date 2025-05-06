import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/extensions/time.dart';
import 'package:mediasink_app/models/video.dart';
import 'package:timeago/timeago.dart' as timeago;

class VideoCard<T> extends StatelessWidget {
  final Video video;
  final Function(T) onBookmark;
  final Function(T) onDelete;
  final VoidCallback onTapVideo;
  final T payload;
  final bool showDownload;

  const VideoCard({
    super.key,
    required this.video,
    required this.onBookmark,
    required this.onDelete,
    required this.onTapVideo, //
    required this.payload,
    this.showDownload = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(6.0),
      elevation: 4,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapVideo,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: video.previewCover,
                    fit: BoxFit.cover,
                    height: 180,
                    width: double.infinity,
                    placeholder: (context, url) => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
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
            ), //
          ),
          // Play button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Text(video.duration.toHHMMSS()),
                const SizedBox(width: 10),
                Text(video.size.toGB()),
                const SizedBox(width: 10),
                Text('${timeago.format(video.createdAt)} ago'),
                const Spacer(),
                if (showDownload)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () => {}, // You can implement the download action here
                    icon: const Icon(Icons.download_rounded),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () => onBookmark(payload),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
                      return ScaleTransition(scale: curvedAnimation, child: child);
                    },
                    child: Icon(Icons.favorite_rounded, key: ValueKey<bool>(video.bookmark == true), color: video.bookmark == true ? Colors.pink : Colors.grey),
                  ),
                ),
                IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, onPressed: () => onDelete(payload), icon: Icon(Icons.delete_rounded, color: Colors.red.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
