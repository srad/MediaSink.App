class Video {
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
    this.bookmark = false, // Default value for bookmark is false
  });
}
