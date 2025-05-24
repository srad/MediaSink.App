import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediaSinkImage extends StatefulWidget {
  final String? imageUrl;
  final bool isRelative;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? preferencesKeyForServerUrl; // Key to retrieve server URL from SharedPreferences
  final DateTime? timeStamp;

  const MediaSinkImage({
    super.key,
    required this.imageUrl,
    this.isRelative = true,
    this.height = 180,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.timeStamp,
    this.errorWidget,
    this.preferencesKeyForServerUrl = 'serverUrl', // Default key
  });

  @override
  State<MediaSinkImage> createState() => _MediaSinkImageState();
}

class _MediaSinkImageState extends State<MediaSinkImage> {
  String? _serverUrl;
  bool _isLoadingServerUrl = false;
  Future<String?>? _serverUrlFuture;

  static final _defaultPlaceholder = const SizedBox(child: Center(child: CircularProgressIndicator()));
  static final _defaultErrorWidget = Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.broken_image, size: 40)));

  @override
  void initState() {
    super.initState();
    if (widget.isRelative) {
      _isLoadingServerUrl = true;
      _serverUrlFuture = _loadServerUrl();
    }
  }

  Future<String?> _loadServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(widget.preferencesKeyForServerUrl!); // Non-null assertion due to isRelative check
    } catch (e) {
      debugPrint("Error loading server URL from preferences: $e");
      return null; // Handle error, maybe return a default or show error state
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingServerUrl = false;
        });
      }
    }
  }

  Widget _buildDefaultPlaceholder(BuildContext context, String url) {
    return const SizedBox(child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildDefaultErrorWidget(BuildContext context, String url, dynamic error) {
    return Container(
      color: Colors.grey[300],
      child: Center(child: Icon(Icons.broken_image, size: widget.height != null ? widget.height! * 0.25 : 40)), //
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRelative) {
      return FutureBuilder<String?>(
        future: _serverUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoadingServerUrl) {
            return widget.placeholder ?? _buildDefaultPlaceholder(context, '');
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            // Handle error in loading server URL or if URL is invalid
            debugPrint("Error or empty server URL: ${snapshot.error ?? 'Server URL is null/empty'}");
            return widget.errorWidget ?? _buildDefaultErrorWidget(context, '', snapshot.error);
          }

          _serverUrl = snapshot.data;
          String fullImageUrl = (_serverUrl != null && _serverUrl!.isNotEmpty && widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ? '$_serverUrl/recordings/${widget.imageUrl}' : widget.imageUrl??''; // Fallback if serverUrl somehow became null after check

          if (widget.timeStamp != null) {
            fullImageUrl += '?ts=${widget.timeStamp!.millisecondsSinceEpoch}';
          }

          return CachedNetworkImage(
            height: widget.height,
            width: widget.width,
            imageUrl: fullImageUrl.isNotEmpty ? fullImageUrl : '',
            // Prevent empty URL errors
            fit: widget.fit,
            placeholder: (context, url) => widget.placeholder ?? _defaultPlaceholder,
            errorWidget: (context, url, error) => widget.errorWidget ?? _defaultErrorWidget, //
          );
        },
      );
    } else {
      // Not relative, use imageUrl directly
      return CachedNetworkImage(
        height: widget.height,
        width: widget.width,
        imageUrl: widget.imageUrl??'',
        fit: widget.fit,
        placeholder: (context, url) => widget.placeholder ?? _defaultPlaceholder,
        errorWidget: (context, url, error) => widget.errorWidget ?? _defaultErrorWidget, //
      );
    }
  }
}
