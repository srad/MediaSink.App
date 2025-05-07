import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/extensions/time.dart';
import 'package:mediasink_app/models/video.dart';
import 'package:mediasink_app/widgets/delete_button.dart';
import 'package:mediasink_app/widgets/fav_button.dart';
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
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(vertical: 6, horizontal: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_rounded),
                      const SizedBox(width: 5),
                      Text(video.duration.toHHMMSS()),
                      const SizedBox(width: 15),
                      Icon(Icons.sd_storage_rounded),
                      const SizedBox(width: 5),
                      Text(video.size.toGB()),
                      const SizedBox(width: 15),
                      Icon(Icons.timelapse_rounded),
                      const SizedBox(width: 5),
                      Text(timeago.format(video.createdAt)), //
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(vertical: 2, horizontal: 4),
                  child: Row(
                    children: [
                      if (showDownload)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: () => {}, // You can implement the download action here
                          icon: const Icon(Icons.download_rounded),
                        ),
                      DeleteButton(onPressed: () => onDelete(payload), iconOnly: true, iconSize: 22),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => {}, // You can implement the download action here
                        icon: const Icon(Icons.local_movies_rounded),
                      ),
                      FavButton(isFav: video.bookmark == true, onPressed: () => onBookmark(payload), iconSize: 22), //
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
