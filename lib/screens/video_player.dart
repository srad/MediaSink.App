import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({super.key, required this.videoUrl, required this.title});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Hide system UI overlays for fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          fullScreenByDefault: false,
          placeholder: Center(child: CircularProgressIndicator()),
          looping: false,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          showControlsOnInitialize: false,
        );
        setState(() {});
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Reset to portrait mode when exiting the player
    // Delay orientation reset slightly
    Future.delayed(Duration(milliseconds: 300), () {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    });

    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final orientation = MediaQuery.of(context).orientation;
    if (_chewieController != null && _chewieController!.isFullScreen) {
      if (orientation == Orientation.portrait) {
        // Exit fullscreen if user rotated to portrait
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _chewieController!.isFullScreen) {
            _chewieController!.exitFullScreen();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return  OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(),
          );
        },
      );
  }

}
