import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/extensions/time.dart';
import 'package:mediasink_app/models/video.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/utils/http_utils.dart';
import 'package:mediasink_app/widgets/confirm_dialog.dart';
import 'package:mediasink_app/widgets/delete_button.dart';
import 'package:mediasink_app/widgets/fav_button.dart';
import 'package:timeago/timeago.dart' as timeago;

class VideoCard<T> extends StatelessWidget {
  final Video video;
  final Function(T)? onBookmarked;
  final Function(T)? onDeleted;
  final Function(T, String)? onError;
  final VoidCallback onTapVideo;
  final T payload;
  final bool showDownload;

  const VideoCard({
    super.key,
    required this.video,
    this.onBookmarked,
    this.onDeleted,
    required this.onTapVideo,
    required this.payload,
    this.onError,
    this.showDownload = true, //
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
                    onPressed: () => _downloadVideo(video), // You can implement the download action here
                    icon: const Icon(Icons.download_rounded),
                  ),
                FavButton(isFav: video.bookmark, onPressed: () => _bookmarkVideo(context, video, payload)),
                DeleteButton(onPressed: () => _deleteVideo(context, video, payload), iconOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future _bookmarkVideo(BuildContext context, Video recording, T payload) async {
    try {
      final client = await RestClientFactory.create();
      if (recording.bookmark == true) {
        await client.recordings.patchRecordingsIdUnfav(id: recording.videoId);
      } else {
        await client.recordings.patchRecordingsIdFav(id: recording.videoId);
      }
      if (onDeleted != null) onDeleted!(payload);
    } catch (e) {
      if (onError != null) onError!(payload, e.toString());
    }
  }

  Future _deleteVideo(BuildContext context, Video recording, T payload) async {
    try {
      await context.confirm(
        title: const Text("Confirm"),
        content: const Text('Do you want to delete the file?'),
        onConfirm: () async {
          final client = await RestClientFactory.create();
          await client.recordings.deleteRecordingsId(id: recording.videoId);
          if (onBookmarked != null) onBookmarked!(payload);
        },
      );
    } catch (e) {
      if (onError != null) onError!(payload, e.toString());
    }
  }

  Future _downloadVideo(Video video) async {
    await HttpUtils.downloadAndSaveFile(fileUrl: video.url, suggestedFileName: video.filename);
  }
}
