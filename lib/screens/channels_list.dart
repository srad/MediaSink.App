import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/extensions/channel.dart';
import 'package:mediasink_app/extensions/file.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/screens/channel_details.dart';
import 'package:mediasink_app/screens/channel_form.dart';
import 'package:mediasink_app/widgets/app_drawer.dart';
import 'package:mediasink_app/widgets/channel_search_app_bar.dart';
import 'package:mediasink_app/widgets/messages.dart';
import 'package:mediasink_app/widgets/recording_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> with TickerProviderStateMixin {
  late Future<List<ServicesChannelInfo>> _futureChannels;
  String _search = "";

  List<ServicesChannelInfo> get _recordingChannels => _channels.where((x) => x.isRecording == true).toList();

  List<ServicesChannelInfo> get _offlineChannels => _channels.where((x) => x.isRecording == false && x.isPaused != true).toList();

  List<ServicesChannelInfo> get _disabledChannels => _channels.where((x) => x.isPaused == true).toList();

  List<ServicesChannelInfo> get _favourites => _channels.where((x) => x.fav == true).toList();

  List<ServicesChannelInfo> get _searchResult => _channels.where((x) => (x.displayName ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

  bool _showFavs = false;
  List<ServicesChannelInfo> _channels = [];
  final Set<int> _loadingChannelIds = {};

  late TabController _tabController;
  final int _numTabs = 3; // Recording, Offline, Disabled

  @override
  void initState() {
    super.initState();
    _futureChannels = fetchChannels();

    _tabController = TabController(length: _numTabs, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Trigger rebuild to update tab icon color
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<ServicesChannelInfo>> fetchChannels() async {
    final client = await RestClientFactory.create();
    final response = await client.channels.getChannels();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = Color.alphaBlend(Colors.white.withValues(alpha: 0.8), Theme.of(context).primaryColor);

    return Scaffold(
      appBar: AppBar(
        title: ChannelSearchAppBar(
          onSearchChanged: (s) {
            setState(() {
              _showFavs = false;
              _search = s;
            });
          },
          onAdd: () => Navigator.pushNamed(context, '/channelForm'),
          onFav: (fav) {
            setState(() {
              _showFavs = fav;
              // Optionally reset tab index when switching away from favs
              if (!fav && _tabController.length > 0) {
                _tabController.animateTo(0);
              }
            });
          },
          isFav: _showFavs,
        ),
        // --- Add TabBar ---
        bottom:
            !_showFavs || _search.isEmpty
                ? TabBar(
                  controller: _tabController,
                  labelColor: labelColor,
                  tabs: [
                    Tab(icon: Icon(Icons.fiber_manual_record, color: _tabController.index == 0 ? Colors.red : null), text: 'Recording'),
                    const Tab(icon: Icon(Icons.videocam_off), text: 'Offline'),
                    const Tab(icon: Icon(Icons.pause), text: 'Paused'), //
                  ],
                )
                : null, // No TabBar when showing favourites
      ),
      drawer: AppDrawer(), // Original Drawer
      body: FutureBuilder<List<ServicesChannelInfo>>(
        future: _futureChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // Original logic to set channels once
            // Check if _channels is empty OR if snapshot data differs significantly
            // For simplicity, just assign if empty or let refresh handle updates.
            if (_channels.isEmpty) {
              _channels = snapshot.data!;
            }
            // If you want refresh to always use the latest fetched data:
            // _channels = snapshot.data!;
          } else {
            // Handle case where snapshot has no data (but also no error)
            _channels = [];
          }

          // --- Replace conditional logic with TabBarView ---
          Widget bodyContent;
          if (_search.isNotEmpty) {
            bodyContent = _buildChannelList(_searchResult, 'Search', key: const ValueKey('search_list'));
          } else if (_showFavs) {
            // Show favourites list directly
            // Add key for AnimatedSwitcher if you wrap this later
            bodyContent = _buildChannelList(_favourites, 'Favs', key: const ValueKey('favs_list'));
          } else {
            // Show TabBarView for other lists
            // Add key for AnimatedSwitcher if you wrap this later
            bodyContent = TabBarView(
              key: const ValueKey('tab_view'),
              controller: _tabController, // Link controller
              children: [
                // Build lists for each tab
                _buildChannelList(_recordingChannels, 'Recording'),
                _buildChannelList(_offlineChannels, 'Offline'),
                _buildChannelList(_disabledChannels, 'Paused'),
              ],
            );
          }

          // Keep AnimatedSwitcher if desired for the transition between favs/tabs
          // Or remove if animation isn't needed here.
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: bodyContent, // The content is now either fav list or TabBarView
          );
        },
      ),
    );
  }

  Widget _buildChannelList(List<ServicesChannelInfo> channels, String label, {Key? key}) {
    if (_search.isNotEmpty && channels.isEmpty) {
      return Center(key: key, child: Text('No search results.'));
    } else if (channels.isEmpty) {
      // Use key here if provided for AnimatedSwitcher
      return Center(key: key, child: Text('No $label channels available.'));
    }

    // Use key here if provided for AnimatedSwitcher
    // Add PageStorageKey to preserve scroll state per list
    return RefreshIndicator(
      key: key,
      onRefresh: () async {
        // Original refresh logic
        setState(() {
          _futureChannels = fetchChannels();
        });
        try {
          _channels = await _futureChannels;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reloaded'), duration: Duration(seconds: 1)));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refresh failed: $e'), backgroundColor: Colors.red));
          }
        }
      },
      child: ListView.builder(
        key: PageStorageKey(label), // Use label to preserve scroll position
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return _video(channel, label);
        },
      ),
    );
  }

  Widget _video(ServicesChannelInfo channel, String label) {
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
                  if (_tabController.index == 2)
                    // Image with grayscale color filter
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation, //
                      ),
                      child: _image(channel.preview),
                    )
                  else
                    _image(channel.preview),
                  if (_tabController.index == 1)
                    const SizedBox(height: 180, width: double.infinity, child: Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white)),
                  if (_tabController.index == 2)
                    const SizedBox(height: 180, width: double.infinity, child: Icon(Icons.pause_rounded, size: 64, color: Colors.white)),
                  if (channel.isRecording == true) //
                    const Positioned(top: 15, right: 15, child: RecordingIndicator()), //
                ],
              ),
              onTap: () {
                if (channel.channelId != null && channel.channelName != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelDetailsScreen(channelId: channel.channelId!, title: channel.channelName!)));
                }
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
                      Text(channel.displayName ?? "No display name", style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis),
                      const SizedBox(width: 4), // Small space before icon
                      const Icon(Icons.link), //
                    ],
                  ),
                  onTap: () async {
                    // Original URL Launching logic
                    final rawUrl = channel.url;
                    if (rawUrl == null || rawUrl.isEmpty) {
                      debugPrint('URL is null or empty');
                      return;
                    }
                    final uri = Uri.tryParse(rawUrl);
                    if (uri == null) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid URL: $rawUrl')));
                      return;
                    }
                    if (!(await canLaunchUrl(uri))) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot launch URL: $rawUrl')));
                      return;
                    }
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
                const Divider(color: Colors.transparent, height: 5),
                Row(
                  children: [
                    // Original Tags display
                    if (channel.tags == null || channel.tags!.isEmpty) // Show placeholder if null or empty
                      ElevatedButton(onPressed: null, style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text('No tags')),
                    // Use Expanded + Wrap for tags if they might overflow
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4, // Spacing if tags wrap to next line
                        children: channel.tags == null ? [] : channel.tags!.map((tag) => ElevatedButton(style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact), child: Text(tag), onPressed: () => {})).toList(),
                      ),
                    ),
                    // Keep Add button separate? Or integrate differently? Original had Spacer() then button.
                    // Spacer(), // Original position
                    ElevatedButton.icon(style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact), icon: const Icon(Icons.add, size: 16), label: const Text('Add'), onPressed: () => {}), // Original Add button
                  ],
                ),
                Divider(color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                  child: Row(
                    // Original stats and actions layout
                    children: [
                      Icon(Icons.sd_storage_rounded, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 5),
                      Text(channel.recordingsSize?.toGB() ?? '0 GB', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 15),
                      Icon(Icons.videocam_rounded, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 5),
                      Text(channel.recordingsCount?.toString() ?? '0', style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      if (_loadingChannelIds.contains(channel.channelId))
                        const SizedBox(width: 24, height: 16, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))))
                      else // Maintain space when not loading
                        const SizedBox(width: 24),
                      // Spacer(), // Original second spacer removed to keep edit icon closer? Adjust as needed.
                      const Text('Pause', style: TextStyle(fontSize: 12)), // Slightly smaller text
                      Switch(
                        value: channel.isPaused ?? false, // Handle null isPaused safely
                        onChanged: _loadingChannelIds.contains(channel.channelId) ? null : (value) => togglePause(channel),
                      ),
                      Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => favChannel(channel), //
                        icon: Icon(channel!.fav == true ? Icons.favorite_rounded : Icons.favorite_outline_rounded, color: channel.fav == true ? Colors.pink : Colors.grey),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => editChannel(channel), //
                        icon: const Icon(Icons.edit_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(String? preview) {
    return CachedNetworkImage(
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      imageUrl: preview != null && preview!.isNotEmpty ? 'http://192.168.0.219:4000/${preview!}' : '',
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 40))), //
    );
  }

  Future<void> togglePause(ServicesChannelInfo channel) async {
    // Add checks for required data
    if (channel.channelId == null || channel.isPaused == null) {
      debugPrint("Cannot toggle pause: Missing channelId or isPaused state.");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot update channel state.'), duration: Duration(seconds: 2)));
      return;
    }

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
                Navigator.pop(context, 'OK'); // Close dialog first
                await togglePauseExecute(channel); // Then execute async action
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> togglePauseExecute(ServicesChannelInfo channel) async {
    final int id = channel.channelId!;

    try {
      final api = await RestClientFactory.create();

      setState(() {
        _loadingChannelIds.add(id);
      });

      if (channel.isPaused!) {
        await api.channels.postChannelsIdResume(id: id);
      } else {
        await api.channels.postChannelsIdPause(id: id);
      }

      setState(() {
        final index = _channels.indexWhere((c) => c.channelId == id);
        if (index != -1) {
          _channels[index] = _channels[index].copyWith(isPaused: !channel.isPaused!);
        }
      });
      if (mounted) snackOk(context, Text('Channel state updated'));
    } catch (e) {
      if (mounted) snackErr(context, Text('Failed to update channel: $e'));
    } finally {
      if (mounted) {
        setState(() {
          _loadingChannelIds.remove(id);
        });
      }
    }
  }

  Future<void> favChannel(ServicesChannelInfo channel) async {
    try {
      final int id = channel.channelId!;
      final bool currentFavStatus = channel.fav!;
      final client = await RestClientFactory.create();

      if (currentFavStatus == true) {
        await client.channels.patchChannelsIdUnfav(id: id);
      } else {
        await client.channels.patchChannelsIdFav(id: id);
      }
      if (mounted) snackOk(context, const Text('Saved'));
      // Original state update
      setState(() {
        final index = _channels.indexWhere((c) => c.channelId == id);
        if (index != -1) {
          // Use the original copyWith extension
          _channels[index] = _channels[index].copyWith(fav: !currentFavStatus);
        }
      });
      snackOk(context, const Text('saved'));
    } catch (e) {
      if (mounted) snackErr(context, Text('Error updating favourite: $e'));
    }
  }

  void editChannel(ServicesChannelInfo channel) async {
    // Basic check - original code didn't have extensive checks here
    if (channel.channelId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot edit channel: Missing ID.')));
      return;
    }

    // Original navigation logic
    final result = await Navigator.push<ServicesChannelInfo>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChannelFormScreen(
              // Map using original ChannelForm structure
              channel: ChannelForm(
                channelId: channel.channelId,
                // Use null-aware operators or defaults as needed based on ChannelForm definition
                channelName: channel.channelName ?? '',
                displayName: channel.displayName ?? '',
                skipStart: channel.skipStart ?? 0,
                minDuration: channel.minDuration ?? 0,
                url: channel.url ?? '',
                tags: channel.tags,
                // Can be null
                fav: channel.fav ?? false,
                isPaused: channel.isPaused ?? false,
              ),
            ),
      ),
      // Original code didn't handle the result, add if needed
    );

    if (result != null && mounted) {
      setState(() {
        _futureChannels = fetchChannels(); // Re-fetch data
      });
    }
  }
}
