import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/extensions/channel.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/extensions/recording.dart';
import 'package:mediasink_app/models/video.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/screens/video_player.dart';
import 'package:mediasink_app/widgets/confirm_dialog.dart';
import 'package:mediasink_app/widgets/delete_button.dart';
import 'package:mediasink_app/widgets/fav_button.dart';
import 'package:mediasink_app/widgets/snack_utils.dart';
import 'package:mediasink_app/widgets/pause_button.dart';
import 'package:mediasink_app/widgets/video_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChannelDetailsScreen extends StatefulWidget {
  final int channelId;
  final String title;

  const ChannelDetailsScreen({super.key, required this.channelId, required this.title});

  @override
  _ChannelDetailsScreenState createState() => _ChannelDetailsScreenState();
}

class _ChannelDetailsScreenState extends State<ChannelDetailsScreen> {
  ServicesChannelInfo? _channel;
  late String? _serverUrl;
  bool _isPausing = false;
  bool _isFaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) => _fetchChannelDetails(widget.channelId));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl');
  }

  Future<void> _fetchChannelDetails(int channelId) async {
    final api = await RestClientFactory.create();
    final channel = await api.channels.getChannelsId(id: channelId);
    channel.recordings?.sort((a, b) => DateTime.parse(b.createdAt!).compareTo(DateTime.parse(a.createdAt!)));
    setState(() {
      _channel = channel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      bottomNavigationBar:
          (_channel != null)
              ? BottomAppBar(
                height: 55,
                child: Row(
                  children: [
                    Icon(Icons.sd_storage_rounded, color: Theme.of(context).primaryColor, size: 22), //
                    const SizedBox(width: 5),
                    Text('${_channel!.recordings?.fold<int>(0, (prev, element) => prev + (element.size ?? 0)).toGB()}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 10),
                    Icon(Icons.videocam_rounded, color: Theme.of(context).primaryColor, size: 22 + 4),
                    const SizedBox(width: 5),
                    Text('${_channel!.recordings?.length ?? 0}', style: const TextStyle(fontSize: 14)),
                    Spacer(),
                    DeleteButton(onPressed: deleteChannel, iconOnly: true, iconSize: 28),
                    PauseButton(isPaused: _channel?.isPaused == true, onPressed: () => _togglePause(), isBusy: _isPausing, iconSize: 28),
                    FavButton(onPressed: favChannel, isBusy: _isFaving, isFav: _channel!.fav!, iconSize: 28),
                  ], //
                ),
              )
              : null,
      body:
          (_channel == null)
              ? const Center(child: CircularProgressIndicator())
              : (_channel?.recordingsCount == 0)
              ? const Center(child: Text('No data available.'))
              : _buildCard(),
    );
  }

  Future<void> favChannel() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _isFaving = true;
      });
      final channel = _channel!;
      final int id = channel.channelId!;
      final bool currentFavStatus = channel.fav!;
      final client = await RestClientFactory.create();

      if (currentFavStatus == true) {
        await client.channels.patchChannelsIdUnfav(id: id);
      } else {
        await client.channels.patchChannelsIdFav(id: id);
      }
      setState(() {
        _channel = _channel!.copyWith(fav: !currentFavStatus);
      });
      if (mounted) messenger.showOk('Saved');
    } catch (e) {
      if (mounted) messenger.showError('Error updating favourite: $e');
    } finally {
      setState(() {
        _isFaving = false;
      });
    }
  }

  Widget _buildCard() {
    return (_channel!.recordingsCount == 0)
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 260, width: 260, child: Image.asset('assets/cat3.png', filterQuality: FilterQuality.high)),
              Text('Empty', style: TextStyle(fontSize: 24)), //
            ],
          ),
        )
        : ListView.separated(
          separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 0),
          itemCount: (_channel!.recordings??[]).length,
          itemBuilder: (context, index) {
            if (_channel == null || _channel?.recordings == null) return SizedBox.shrink();
            final channel = _channel!;

            final item = channel.recordings?[index];
            if (item == null) return SizedBox.shrink();
            final recording = item!;

            return VideoCard(
              payload: recording,
              video: Video(
                videoId: recording.recordingId!,
                filename: recording.filename,
                url: '$_serverUrl/recordings/${recording.pathRelative}',
                duration: recording.duration!,
                size: recording.size!,
                bookmark: recording.bookmark!,
                createdAt: DateTime.tryParse(recording.createdAt!) ?? DateTime.now(),
                previewCover: '$_serverUrl/recordings/${recording.previewCover ?? channel.preview}', //
              ),
              onBookmarked: _videoBookmarked,
              onDeleted: _videoDeleted,
              onError: _errorDelete,
              onTapVideo: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(title: _channel!.channelName!, videoUrl: '$_serverUrl/recordings/${recording.pathRelative}'))), //
            );
          },
        );
  }

  Future<void> _togglePause() async {
    if (_channel == null) return;
    final channel = _channel!;

    await context.confirm(
      title: Text('Confirm'),
      content: Text('Do you want to ${channel.isPaused == true ? 'resume' : 'pause'} stream recording for this channel?'),
      onConfirm: () async {
        Navigator.pop(context, 'OK'); // Close dialog first
        await _togglePauseExecute(); // Then execute async action
      },
    );
  }

  Future<void> _togglePauseExecute() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final channel = _channel!;
      final int id = channel.channelId!;
      final api = await RestClientFactory.create();

      setState(() {
        _isPausing = true;
      });

      if (channel.isPaused!) {
        await api.channels.postChannelsIdResume(id: id);
      } else {
        await api.channels.postChannelsIdPause(id: id);
      }

      setState(() {
        _channel = channel.copyWith(isPaused: channel.isPaused);
      });
      if (mounted) messenger.showOk('Channel state updated');
    } catch (e) {
      if (mounted) messenger.showError('Failed to update channel: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPausing = false;
        });
      }
    }
  }

  void deleteChannel() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.confirm(
        title: const Text('Confirm'),
        content: Text('Do you want to delete the channel: ${_channel!.displayName}?'),
        onConfirm: () async {
          final client = await RestClientFactory.create();
          await client.channels.deleteChannelsId(id: _channel!.channelId!);

          messenger.showOk('Channel "${_channel?.displayName}" deleted');

          // First pop the dialog
          Navigator.of(context, rootNavigator: true).pop();

          // Then pop the screen (after the dialog is dismissed)
          Navigator.of(context).pop(); // or use a named route if needed
        },
      );
    } catch (e) {
      if (mounted) messenger.showError(e.toString());
    }
  }

  _videoBookmarked(DatabaseRecording recording) {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      final index = _channel!.recordings?.indexWhere((rec) => rec.recordingId == recording.recordingId);
      if (index != -1) {
        _channel!.recordings?[index!] = recording.copyWith(bookmark: !recording.bookmark!);
      }
    });
    if (mounted) messenger.showOk('Saved');
  }

  _videoDeleted(DatabaseRecording recording) {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _channel!.recordings?.removeWhere((rec) => rec.recordingId == recording.recordingId);
    });
    if (mounted) messenger.showOk('Deleted');
  }

  _errorDelete(DatabaseRecording recording, String message) {
    if (mounted) ScaffoldMessenger.of(context).showError(message);
  }
}
