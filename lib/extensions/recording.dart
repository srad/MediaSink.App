import 'package:mediasink_app/api/export.dart';

extension DatabaseRecordingCopyWith on DatabaseRecording {
  DatabaseRecording copyWith({int? bitRate, bool? bookmark, int? channelId, String? channelName, String? createdAt, num? duration, String? filename, int? height, int? packets, String? pathRelative, String? previewCover, String? previewStripe, String? previewVideo, int? recordingId, int? size, String? videoType, int? width}) {
    return DatabaseRecording(
      bitRate: bitRate ?? this.bitRate,
      bookmark: bookmark ?? this.bookmark,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      filename: filename ?? this.filename,
      height: height ?? this.height,
      packets: packets ?? this.packets,
      pathRelative: pathRelative ?? this.pathRelative,
      previewCover: previewCover ?? this.previewCover,
      previewStripe: previewStripe ?? this.previewStripe,
      previewVideo: previewVideo ?? this.previewVideo,
      recordingId: recordingId ?? this.recordingId,
      size: size ?? this.size,
      videoType: videoType ?? this.videoType,
      width: width ?? this.width,
    );
  }
}
