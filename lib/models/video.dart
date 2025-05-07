class Video {
  final int videoId;
  final num duration;
  final int size;
  final DateTime createdAt;
  bool bookmark;
  final String previewCover;
  String? url;
  String? channelName;

  Video({
    required this.videoId,
    required this.duration,
    required this.size,
    required this.createdAt,
    required this.previewCover,
    this.bookmark = false,
    this.url,
    this.channelName, //
  });
}
