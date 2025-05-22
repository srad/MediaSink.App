class Video {
  final int? channelId;
  final int videoId;
  final num duration;
  final int size; // assuming size is in GB or any other unit you'd like
  final DateTime createdAt;
  bool bookmark;
  final String previewCover;
  final String url;
  final String filename;

  // Constructor
  Video({
    required this.videoId,
    required this.duration,
    required this.size,
    required this.createdAt,
    required this.previewCover,
    required this.url,
    required this.filename,
    this.channelId,
    this.bookmark = false, // Default value for bookmark is false
  });

  Video copyWith({
    int? videoId,
    num? duration,
    int? size,
    DateTime? createdAt,
    bool? bookmark,
    String? previewCover,
    String? url,
    String? filename,
  }) {
    return Video(
      videoId: videoId ?? this.videoId,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      bookmark: bookmark ?? this.bookmark,
      previewCover: previewCover ?? this.previewCover,
      url: url ?? this.url,
      filename: filename ?? this.filename,
    );
  }
}
