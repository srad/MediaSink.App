import 'package:flutter/material.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/extensions/time.dart';
import 'package:mediasink_app/models/video.dart';
import 'package:mediasink_app/factories/rest_client_factory.dart';
import 'package:mediasink_app/utils/http_utils.dart';
import 'package:mediasink_app/widgets/confirm_dialog.dart';
import 'package:mediasink_app/widgets/delete_button.dart';
import 'package:mediasink_app/widgets/fav_button.dart';
import 'package:mediasink_app/widgets/mediasink_image.dart';
import 'package:mediasink_app/widgets/snack_utils.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class VideoCard<T> extends StatelessWidget {
  final Video video;
  final Function(T)? onBookmarked;
  final Function(T)? onDeleted;
  final Function(T)? onParent;
  final Function(T, String)? onError;
  final VoidCallback onTapVideo;
  final T payload;
  final bool showDownload;
  final bool showChannelLink;
  final double iconSize;

  const VideoCard({
    super.key,
    required this.video,
    this.onBookmarked,
    this.onDeleted,
    this.onParent,
    required this.onTapVideo,
    required this.payload,
    this.onError,
    this.showChannelLink = false,
    this.showDownload = true,
    this.iconSize = 22, //
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(0),
      elevation: 4,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapVideo,
            child: Stack(alignment: Alignment.center, children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: MediaSinkImage(imageUrl: video.previewCover)), const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70)]), //
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(vertical: 6, horizontal: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_rounded, size: iconSize),
                      const SizedBox(width: 5),
                      Text(video.duration.toHHMMSS()),
                      const SizedBox(width: 15),
                      Icon(Icons.sd_storage_rounded, size: iconSize),
                      const SizedBox(width: 5),
                      Text(video.size.toGB()),
                      const SizedBox(width: 15),
                      Icon(Icons.timelapse_rounded, size: iconSize),
                      const SizedBox(width: 5),
                      Text(timeago.format(video.createdAt, locale: 'en_short')), //
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
                          onPressed: () async {
                            final result = await HttpUtils.downloadAndSaveFile(fileUrl: video.url, suggestedFileName: video.filename);
                            switch (result) {
                              case DownloadStatus.enqueued:
                                if (context.mounted) ScaffoldMessenger.of(context).showOk('Enqueued download ...');
                              case DownloadStatus.canceled:
                                if (context.mounted) ScaffoldMessenger.of(context).showError('Canceled download');
                              case DownloadStatus.error:
                                if (context.mounted) ScaffoldMessenger.of(context).showError('Canceled download');
                              case DownloadStatus.unknown:
                                if (context.mounted) ScaffoldMessenger.of(context).showOk('Status unknown');
                            }
                          },
                          icon: const Icon(Icons.download_rounded),
                          iconSize: iconSize,
                        ),
                      DeleteButton(
                        onPressed: () => _deleteVideo(context, video, payload),
                        iconOnly: true,
                        iconSize: iconSize + 2, //
                      ),
                      if (showChannelLink)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (onParent != null) onParent!(payload);
                          },
                          // You can implement the download action here
                          icon: const Icon(Icons.grid_view_rounded),
                          iconSize: iconSize + 2, //
                        ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => {},
                        // You can implement the download action here
                        icon: const Icon(Icons.local_movies_rounded),
                        iconSize: iconSize + 2,
                      ),
                      FavButton(isFav: video.bookmark == true, onPressed: () => _bookmarkVideo(context, video, payload), iconSize: iconSize + 2), //
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

  Future _bookmarkVideo(BuildContext context, Video recording, T payload) async {
    try {
      final factory = context.read<RestClientFactory>();
      final client = await factory.create();
      if (recording.bookmark == true) {
        await client?.recordings.patchRecordingsIdUnfav(id: recording.videoId);
      } else {
        await client?.recordings.patchRecordingsIdFav(id: recording.videoId);
      }
      if (onBookmarked != null) onBookmarked!(payload);
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
          final factory = context.read<RestClientFactory>();
          final client = await factory.create();
          await client?.recordings.deleteRecordingsId(id: recording.videoId);
          if (onDeleted != null) onDeleted!(payload);
        },
      );
    } catch (e) {
      if (onError != null) onError!(payload, e.toString());
    }
  }
}
