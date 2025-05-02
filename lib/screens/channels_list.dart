import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mediasink_app/api_factory.dart';
import 'package:mediasink_app/api/export.dart';

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

  List<ServicesChannelInfo> _recordingChannels = [];
  List<ServicesChannelInfo> _offlineChannels = [];
  List<ServicesChannelInfo> _disabledChannels = [];
  List<ServicesChannelInfo> _favourites = [];

  bool _showFavs = false;

  List<ServicesChannelInfo> channels = [];

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
        title: Row(
          children: [
            const Text('Channels'),
            Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  _showFavs = !_showFavs;
                });
              },
              icon: Icon(Icons.favorite, color: _showFavs ? Colors.pink : Colors.grey),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<ServicesChannelInfo>>(
        future: _futureChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(animation);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            child: KeyedSubtree(
              // Important: Give each list a unique key to trigger switch
              key: ValueKey(_showFavs ? 'favs' : _selectedIndex),
              child: listWidget,
            ),
          );
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
                  BottomNavigationBarItem(icon: Icon(Icons.fiber_manual_record), label: 'Recording'),
                  BottomNavigationBarItem(icon: Icon(Icons.cloud_off), label: 'Offline'),
                  BottomNavigationBarItem(icon: Icon(Icons.pause_circle_filled), label: 'Disabled'),
                  //BottomNavigationBarItem(icon: Icon(Icons.favorite, color: Colors.pink), label: 'Favs'),
                ],
              )
              : null,
    );
  }

  Future<void> togglePause(ServicesChannelInfo channel) async {
    final apiClient = await ApiClientFactory().create();

    if (channel.isPaused!) {
      await apiClient.resume(channel.channelId!);
    } else {
      await apiClient.pause(channel.channelId!);
    }

    setState(() {
      final updated = channel.copyWith(isPaused: !channel.isPaused!);

      // Update in all relevant lists
      void replaceIn(List<ServicesChannelInfo> list) {
        final index = list.indexWhere((c) => c.channelId == channel.channelId);
        if (index != -1) {
          list[index] = updated;
        }
      }

      replaceIn(_recordingChannels);
      replaceIn(_offlineChannels);
      replaceIn(_disabledChannels);
      replaceIn(_favourites);
    });
  }

  Widget _buildChannelList(List<ServicesChannelInfo> channels, String label) {
    if (channels.isEmpty) {
      return Center(child: Text('No $label channels available.'));
    }

    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return Card(
          margin: const EdgeInsets.all(6.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (channel.preview != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), //
                  child: CachedNetworkImage(
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageUrl: 'http://192.168.0.219:4000/${channel.preview!}',
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 40))), //
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channel.displayName ?? "No display name", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(channel.url!, style: const TextStyle(color: Colors.blueGrey)),
                    const SizedBox(height: 6),
                    Divider(color: Colors.grey.shade300),
                    Row(children: [const Text('Tags', style: TextStyle(fontSize: 16)), Spacer(), Wrap(spacing: 8, children: channel.tags == null ? [] : channel.tags!.map((tag) => Chip(label: Text(tag))).toList())]),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Fav'),
                        IconButton(onPressed: () => favChannel(channel), icon: Icon(Icons.favorite, color: channel.fav == true ? Colors.pink : Colors.grey)), //
                        const Text('Paused'), Switch(value: channel.isPaused!, onChanged: (value) => togglePause(channel)), Spacer(), ElevatedButton(onPressed: () {}, child: Text('Edit')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> favChannel(ServicesChannelInfo channel) async {
    final apiClient = await ApiClientFactory().create();
    if (channel.fav!) {
      await apiClient.unfavChannel(channel.channelId!);
    } else {
      await apiClient.favChannel(channel.channelId!);
    }

    setState(() {
      final updated = channel.copyWith(fav: !channel.fav!);
    });
  }
}
