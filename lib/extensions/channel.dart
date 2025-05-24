import 'package:mediasink_app/api/export.dart';

extension ServicesChannelInfoCopyWith on ServicesChannelInfo {
  ServicesChannelInfo copyWith({
    List<DatabaseRecording>? recordings,
    int? channelId,
    String? createdAt,
    bool? deleted,
    String? channelName,
    String? displayName,
    bool? isRecording,
    bool? isOnline,
    bool? isPaused,
    bool? fav,
    int? skipStart,
    int? minDuration,
    String? url,
    List<String>? tags,
    int? minRecording,
    int? recordingsSize,
    int? recordingsCount,
    String? preview,
    DateTime? timeStamp, //
  }) {
    return ServicesChannelInfo(
      timeStamp: timeStamp ?? DateTime.now(),
      recordings: recordings ?? this.recordings,
      channelId: channelId ?? this.channelId,
      createdAt: createdAt ?? this.createdAt,
      deleted: deleted ?? this.deleted,
      channelName: channelName ?? this.channelName,
      displayName: displayName ?? this.displayName,
      isRecording: isRecording ?? this.isRecording,
      isOnline: isOnline ?? this.isOnline,
      isPaused: isPaused ?? this.isPaused,
      fav: fav ?? this.fav,
      skipStart: skipStart ?? this.skipStart,
      minDuration: minDuration ?? this.minDuration,
      url: url ?? this.url,
      tags: tags ?? this.tags,
      minRecording: minRecording ?? this.minRecording,
      recordingsCount: recordingsCount ?? this.recordingsCount,
      recordingsSize: recordingsSize ?? this.recordingsSize,
      preview: preview ?? this.preview, //
    );
  }
}
