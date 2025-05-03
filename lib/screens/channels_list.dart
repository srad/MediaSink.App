import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart';
import 'package:mediasink_app/api_factory.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/screens/channel_details.dart';
import 'package:mediasink_app/screens/channel_form.dart';
import 'package:mediasink_app/widgets/app_drawer.dart';
import 'package:mediasink_app/widgets/channel_search_app_bar.dart';
import 'package:mediasink_app/widgets/recording_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

extension ServicesChannelInfoCopyWith on ServicesChannelInfo {
  ServicesChannelInfo copyWith({
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
    String? preview, //
  }) {
    return ServicesChannelInfo(
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

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  late Future<List<ServicesChannelInfo>> _futureChannels;
  int _selectedIndex = 0;

  List<ServicesChannelInfo> get _recordingChannels => _channels.where((x) => x.isRecording == true).toList();

  List<ServicesChannelInfo> get _offlineChannels => _channels.where((x) => x.isRecording == false && x.isPaused != true).toList();

  List<ServicesChannelInfo> get _disabledChannels => _channels.where((x) => x.isPaused == true).toList();

  List<ServicesChannelInfo> get _favourites => _channels.where((x) => x.fav == true).toList();

  bool _showFavs = false;

  List<ServicesChannelInfo> _channels = [];

  final Set<int> _loadingChannelIds = {};

  @override
  void initState() {
    super.initState();
    _futureChannels = fetchChannels();
  }

  Future<List<ServicesChannelInfo>> fetchChannels() async {
    final apiClient = await ApiClientFactory().create();
    final response = await apiClient.get('/channels');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final channels = jsonList.map((json) => ServicesChannelInfo.fromJson(json)).toList();
      if (channels != null && channels.isNotEmpty) {
        channels.sort((a, b) => a.displayName!.compareTo(b.displayName!));
        return channels;
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load channels');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ChannelSearchAppBar(
          onSearchChanged: (p0) => {},
          onAdd: () => Navigator.pushNamed(context, '/channelForm'),
          onFav: (fav) {
            setState(() {
              _showFavs = fav;
            });
          },
        ),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder<List<ServicesChannelInfo>>(
        future: _futureChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // ✅ Set the channels here once
            if (_channels.isEmpty) {
              _channels = snapshot.data!;
            }
          }

          Widget listWidget;

          if (_showFavs) {
            listWidget = _buildChannelList(_favourites, 'Favs');
          } else if (_selectedIndex == 0) {
            listWidget = _buildChannelList(_recordingChannels, 'Recording');
          } else if (_selectedIndex == 1) {
            listWidget = _buildChannelList(_offlineChannels, 'Offline');
          } else {
            listWidget = _buildChannelList(_disabledChannels, 'Disabled');
          }

          return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: listWidget);

          // return AnimatedSwitcher(
          //   duration: const Duration(milliseconds: 200),
          //   transitionBuilder: (child, animation) {
          //     final offsetAnimation = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(animation);
          //     return SlideTransition(position: offsetAnimation, child: child);
          //   },
          //   child: KeyedSubtree(
          //     // Important: Give each list a unique key to trigger switch
          //     key: ValueKey(_showFavs ? 'favs' : _selectedIndex),
          //     child: listWidget,
          //   ),
          // );
        },
      ),
      bottomNavigationBar:
          !_showFavs
              ? BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(icon: Icon(Icons.fiber_manual_record, color: Colors.red), label: 'Recording'),
                  BottomNavigationBarItem(icon: Icon(Icons.cloud_off), label: 'Offline'),
                  BottomNavigationBarItem(icon: Icon(Icons.pause_circle_filled), label: 'Disabled'),
                  //BottomNavigationBarItem(icon: Icon(Icons.favorite, color: Colors.pink), label: 'Favs'),
                ],
              )
              : null,
    );
  }

  Widget _buildChannelList(List<ServicesChannelInfo> channels, String label) {
    if (channels.isEmpty) {
      return Center(child: Text('No $label channels available.'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureChannels = fetchChannels();
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reloaded')));
        },
        child: ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: GestureDetector(
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            imageUrl: 'http://192.168.0.219:4000/${channel.preview!}',
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 40))), //
                          ),
                          // The blinking red dot in the top-right corner
                          if (channel.isRecording == true) Positioned(top: 15, right: 15, child: RecordingIndicator()),
                        ],
                      ),
                      onTap: () {
                        // Navigate to the Channel Details screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChannelDetailsScreen(channelId: channel.channelId!, title: channel.channelName!), //
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          child: Row(
                            children: [
                              Text(channel.displayName ?? "No display name", style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary)),
                              Icon(Icons.link), //
                            ],
                          ),
                          onTap: () async {
                            final rawUrl = channel.url;
                            if (rawUrl == null || rawUrl.isEmpty) {
                              debugPrint('URL is null or empty');
                              return;
                            }
                            final uri = Uri.tryParse(rawUrl);
                            if (uri == null || !(await canLaunchUrl(uri))) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid or unsupported URL: $rawUrl')));
                              return;
                            }
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                        ),
                        Divider(color: Colors.transparent, height: 5),
                        Row(
                          children: [
                            if (channel.tags == null) ElevatedButton(onPressed: () => {}, child: const Text('No tags')),
                            Wrap(spacing: 8, children: channel.tags == null ? [] : channel.tags!.map((tag) => ElevatedButton(child: Text(tag), onPressed: () => {})).toList()),
                            Spacer(),
                            ElevatedButton(onPressed: () => {}, child: Row(children: [Icon(Icons.add), const Text('Add')])), //
                          ],
                        ),
                        Divider(color: Colors.grey.shade300),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                          child: Row(
                            children: [
                              Text(channel.recordingsSize!.toGB(), style: TextStyle(fontSize: 14)),
                              SizedBox(width: 5),
                              Icon(Icons.storage),
                              SizedBox(width: 15),
                              Text(channel.recordingsCount.toString(), style: TextStyle(fontSize: 14)),
                              SizedBox(width: 5),
                              Icon(Icons.video_library_sharp),
                              Spacer(),
                              IconButton(onPressed: () => favChannel(channel), icon: Icon(Icons.favorite, color: channel.fav == true ? Colors.pink : Colors.grey)),
                              const Text('Pause'),
                              Switch(value: channel.isPaused!, onChanged: _loadingChannelIds.contains(channel.channelId!) ? null : (value) => togglePause(channel)),
                              if (_loadingChannelIds.contains(channel.channelId!)) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              Spacer(),
                              IconButton(onPressed: () => editChannel(channel), icon: Icon(Icons.edit)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> togglePause(ServicesChannelInfo channel) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(channel.isPaused! ? 'Resume recording' : 'Pause recording'),
          content: Text(channel.isPaused! ? 'Do you want to allow stream recording?' : 'Do you want to pause any stream recording for this channel?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context, 'Cancel'), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await togglePauseExecute(channel);
                Navigator.pop(context, 'OK');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> togglePauseExecute(ServicesChannelInfo channel) async {
    final apiClient = await ApiClientFactory().create();

    setState(() {
      _loadingChannelIds.add(channel.channelId!);
    });

    try {
      if (channel.isPaused!) {
        await apiClient.resume(channel.channelId!);
      } else {
        await apiClient.pause(channel.channelId!);
      }

      setState(() {
        final updated = channel.copyWith(isPaused: !channel.isPaused!);
        final index = _channels.indexWhere((c) => c.channelId == channel.channelId);
        if (index != -1) {
          _channels[index] = updated;
        }
      });
    } catch (e) {
      // Optional: show error
      print('Failed to toggle pause: $e');
    } finally {
      setState(() {
        _loadingChannelIds.remove(channel.channelId!);
      });
    }
  }

  Future<void> favChannel(ServicesChannelInfo channel) async {
    final apiClient = await ApiClientFactory().create();

    Response? response;
    if (channel.fav == true) {
      response = await apiClient.unfavChannel(channel.channelId!);
    } else {
      response = await apiClient.favChannel(channel.channelId!);
    }

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ✅'), backgroundColor: Colors.green.shade500));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${response.body} ❌'), backgroundColor: Colors.red.shade300));
      return;
    }

    setState(() {
      final updated = channel.copyWith(fav: !channel.fav!);
      final index = _channels.indexWhere((c) => c.channelId == channel.channelId);
      if (index != -1) {
        _channels[index] = updated;
      }
    });
  }

  void editChannel(ServicesChannelInfo channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChannelFormScreen(
              channel: ChannelForm(
                channelId: channel.channelId,
                channelName: channel.channelName!,
                displayName: channel.displayName!,
                skipStart: channel.skipStart!,
                minDuration: channel.minDuration!,
                url: channel.url!,
                tags: channel.tags,
                fav: channel.fav!,
                isPaused: channel.isPaused!,
              ),
            ),
      ),
    );
  }
}
