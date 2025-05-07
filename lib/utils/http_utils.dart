import 'package:background_downloader/background_downloader.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:mediasink_app/utils/storage_utils.dart';

enum DownloadStatus{enqueued, canceled, error, unknown}

class HttpUtils {
  static Future<DownloadStatus> downloadAndSaveFile({required String fileUrl, required String suggestedFileName}) async {
    try {
      final isGranted = await StorageUtils.requestStoragePermission();
      if (!isGranted) {
        return DownloadStatus.canceled;
      }

      final String? directoryPath = await getDirectoryPath();
      if (directoryPath == null) {
        // Operation was canceled by the user.
        return DownloadStatus.canceled;
      }

      FileDownloader().configureNotification(
        running: TaskNotification('Downloading {filename}', 'Download in progress'),
        complete: TaskNotification('Download complete', '{filename} saved'),
        error: TaskNotification('Download failed', 'Error downloading {filename}'),
        progressBar: true, //
      );

      final taskId = await FlutterDownloader.enqueue(
        url: fileUrl,
        fileName: suggestedFileName,
        savedDir: directoryPath,
        showNotification: true, // show download progress in status bar (for Android)
        openFileFromNotification: true, // click on notification to open downloaded file (for Android)
      );

      if (taskId != null) {
        return DownloadStatus.enqueued;
      }
      return DownloadStatus.error;
    } catch (e) {
      return DownloadStatus.error;
    }
  }
}
