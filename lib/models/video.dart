class Video {
  final int videoId;
  final num duration;
  final int size; // assuming size is in GB or any other unit you'd like
  final DateTime createdAt;
  bool bookmark;
  final String previewCover;

  // Constructor
  Video({
    required this.videoId,
    required this.duration,
    required this.size,
    required this.createdAt,
    required this.previewCover,
    this.bookmark = false, // Default value for bookmark is false
  });
}
