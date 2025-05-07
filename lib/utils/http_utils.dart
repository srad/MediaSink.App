import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';

class HttpUtils {
  static Future<void> downloadAndSaveFile({required String fileUrl, required String suggestedFileName, Function(String)? onSaved, Function(String)? onError, Function? onCancel}) async {
    try {
      // Step 1: Ask user where to save
      final path = await getSaveLocation(suggestedName: suggestedFileName);
      if (path == null) {
        if (onCancel != null) onCancel();
        return;
      }

      // Step 2: Download the file using Dio
      final dio = Dio();
      final response = await dio.download(
        fileUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      if (onSaved != null) onSaved('$path');
    } catch (e) {
      if (onError != null) onError('$e');
    }
  }
}
