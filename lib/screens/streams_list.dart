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
import 'package:mediasink_app/widgets/confirm_dialog.dart';
import 'package:mediasink_app/widgets/delete_button.dart';
import 'package:mediasink_app/widgets/fav_button.dart';
import 'package:mediasink_app/widgets/pause_button.dart';
import 'package:mediasink_app/widgets/snack_utils.dart';
import 'package:mediasink_app/widgets/recording_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamsListScreen extends StatefulWidget {
  const StreamsListScreen({super.key});

  @override
  State<StreamsListScreen> createState() => _StreamsListScreenState();
}

class _StreamsListScreenState extends State<StreamsListScreen> with TickerProviderStateMixin {
  final ValueNotifier<List<ServicesChannelInfo>> _channelsListNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  String _search = "";

  List<ServicesChannelInfo> get _recordingChannels => _channelsListNotifier.value.where((x) => x.isRecording == true).toList();

  List<ServicesChannelInfo> get _offlineChannels => _channelsListNotifier.value.where((x) => x.isRecording == false && x.isPaused != true).toList();

  List<ServicesChannelInfo> get _disabledChannels => _channelsListNotifier.value.where((x) => x.isPaused == true).toList();

  List<ServicesChannelInfo> get _favourites => _channelsListNotifier.value.where((x) => x.fav == true).toList();

  List<ServicesChannelInfo> get _searchResult => _channelsListNotifier.value.where((x) => (x.displayName ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

  bool _showFavs = false;
  final Set<int> _loadingChannelIds = {};
  final Set<int> _favChannels = {};
  final double _iconSize = 28;

  late TabController _tabController;
  final int _numTabs = 3; // Recording, Offline, Disabled

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _tabController = TabController(length: _numTabs, vsync: this);
  }

  Future _loadChannels() async {
    _isLoading.value = true;
    try {
      final channels = await fetchChannels();
      _channelsListNotifier.value = channels;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showError('$e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future _refresh() async {
    await _loadChannels();
    if (mounted) ScaffoldMessenger.of(context).showOk('Reloaded');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<ServicesChannelInfo>> fetchChannels() async {
    final client = await RestClientFactory.create();
    final response = await client.channels.getChannels();
    response.sort((a, b) => a.displayName!.compareTo(b.displayName!));
    return response;
  }

  @override
  Widget build(final BuildContext context) {
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
        bottom: !_showFavs || !_showFavs && _search.isEmpty ? _tabs() : null, // No TabBar when showing favourites
      ),
      drawer: AppDrawer(), // Original Drawer
      body: ValueListenableBuilder<List<ServicesChannelInfo>>(
        valueListenable: _channelsListNotifier,
        builder: (context, channels, _) {
          return ValueListenableBuilder(valueListenable: _isLoading, builder: (context, isLoading, child) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (channels.isEmpty) {
              return const Center(child: Text("No channels"));
            }

            Widget bodyContent;
            if (_search.isNotEmpty) {
              bodyContent = _buildChannelList(_searchResult, 'Search', key: const ValueKey('search_list'));
            } else if (_showFavs) {
              // Add key for AnimatedSwitcher if you wrap this later
              bodyContent = _buildChannelList(_favourites, 'Favs', key: const ValueKey('favs_list'));
            } else {
              // Add key for AnimatedSwitcher if you wrap this later
              bodyContent = TabBarView(
                key: const ValueKey('tab_view'),
                controller: _tabController, // Link controller
                children: [_buildChannelList(_recordingChannels, 'Recording'), _buildChannelList(_offlineChannels, 'Offline'), _buildChannelList(_disabledChannels, 'Paused')],
              );
            }

            return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: bodyContent);
          });
        },
      ),
    );
  }

  Widget _buildChannelList(final List<ServicesChannelInfo> channels, final String label, {Key? key}) {
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
      onRefresh: _refresh,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: channels.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 450,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.17, // 👈 tweak this until items look right
        ),
        key: PageStorageKey(label), // Use label to preserve scroll position
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
              child: AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, child) {
                  final tabIndex = _tabController.animation!.value.round();

                  return _buildPreviewOverlay(channel, tabIndex);
                },
              ),
              onTap: () {
                if (channel.channelId != null && channel.channelName != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelDetailsScreen(channelId: channel.channelId!, title: channel.channelName!)));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: Row(
                      children: [
                        Text(channel.displayName ?? "No display name", style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis),
                        const SizedBox(width: 4), // Small space before icon
                        const Icon(Icons.link), //
                      ],
                    ),
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
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: Row(
                    children: [
                      Icon(Icons.sd_storage_rounded, color: Theme.of(context).primaryColor, size: _iconSize), //
                      const SizedBox(width: 5),
                      Text(channel.recordingsSize?.toGB() ?? '0 GB', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 10),
                      Icon(Icons.videocam_rounded, color: Theme.of(context).primaryColor, size: _iconSize),
                      const SizedBox(width: 5),
                      Text(channel.recordingsCount?.toString() ?? '0', style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      DeleteButton(onPressed: () => deleteChannel(channel), iconSize: _iconSize, iconOnly: true),
                      IconButton(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        // Removes default min size
                        iconSize: _iconSize,
                        onPressed: () => editChannel(channel),
                        //
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      PauseButton(isPaused: channel.isPaused == true, onPressed: () => togglePause(channel), iconSize: _iconSize + 4),
                      const SizedBox(width: 8),
                      FavButton(onPressed: () => favChannel(channel), isFav: channel.fav == true, isBusy: _favChannels.contains(channel.channelId), iconSize: _iconSize + 4),
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

  Widget _buildPreviewOverlay(final ServicesChannelInfo channel, final int tabIndex) {
    final imageWidget = _image(channel.preview);
    final filteredImage = tabIndex == 2 ? ColorFiltered(colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation), child: imageWidget) : imageWidget;

    return Stack(
      children: [
        filteredImage,
        if (tabIndex == 1) const Center(child: SizedBox(height: 180, child: Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white))),
        if (tabIndex == 2) const Center(child: SizedBox(height: 180, child: Icon(Icons.pause_rounded, size: 64, color: Colors.white))),
        if (channel.isRecording == true)
          const Positioned(
            top: 15,
            right: 15,
            child: RecordingIndicator(), //
          ),
      ],
    );
  }

  Widget _image(final String? preview) {
    return CachedNetworkImage(
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      imageUrl: preview != null && preview!.isNotEmpty ? 'http://192.168.0.219:3000/recordings/${preview!}' : '',
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 40))), //
    );
  }

  Future<void> togglePause(final ServicesChannelInfo channel) async {
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

  Future<void> togglePauseExecute(final ServicesChannelInfo channel) async {
    final int id = channel.channelId!;
    final messenger = ScaffoldMessenger.of(context);
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

      final index = _channelsListNotifier.value.indexWhere((c) => c.channelId == id);
      if (index != -1) {
        final List<ServicesChannelInfo> newList = List.from(_channelsListNotifier.value);
        newList[index] = channel.copyWith(isPaused: !channel.isPaused!);
        _channelsListNotifier.value = newList;
      }
      if (mounted) messenger.showOk('Channel state updated');
    } catch (e) {
      if (mounted) messenger.showError('Failed to update channel: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingChannelIds.remove(id);
        });
      }
    }
  }

  Future<void> favChannel(final ServicesChannelInfo channel) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() => _favChannels.add(channel.channelId!));
      final int id = channel.channelId!;
      final bool currentFavStatus = channel.fav!;
      final client = await RestClientFactory.create();

      if (currentFavStatus == true) {
        await client.channels.patchChannelsIdUnfav(id: id);
      } else {
        await client.channels.patchChannelsIdFav(id: id);
      }
      final index = _channelsListNotifier.value.indexWhere((c) => c.channelId == id);
      if (index != -1) {
        final List<ServicesChannelInfo> newList = List.from(_channelsListNotifier.value);
        newList[index] = channel.copyWith(fav: !currentFavStatus);
        _channelsListNotifier.value = newList;
      }
      if (mounted) messenger.showOk('Saved');
    } catch (e) {
      if (mounted) messenger.showError('Error updating favourite: $e');
    } finally {
      setState(() => _favChannels.remove(channel.channelId!));
    }
  }

  void deleteChannel(final ServicesChannelInfo channel) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.confirm(
        title: const Text('Confirm'),
        content: Text('Do you want to delete the channel: ${channel.displayName}?'),
        onConfirm: () async {
          final client = await RestClientFactory.create();
          await client.channels.deleteChannelsId(id: channel.channelId!);
          setState(() {
            _channelsListNotifier.value.removeWhere((c) => c.channelId == channel.channelId!);
          });
        },
      );
    } catch (e) {
      if (mounted) messenger.showError(e.toString());
    }
  }

  void editChannel(final ServicesChannelInfo channel) async {
    // Basic check - original code didn't have extensive checks here
    if (channel.channelId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot edit channel: Missing ID.')));
      return;
    }

    // Original navigation logic
    final result = await Navigator.push(
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

    await _loadChannels();
  }

  PreferredSize _tabs() {
    final labelColor = Color.alphaBlend(Colors.white.withValues(alpha: 0.8), Theme.of(context).primaryColor);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, _) {
          final currentIndex = _tabController.animation!.value.round();

          return TabBar(
            controller: _tabController,
            labelColor: labelColor,
            tabs: [
              Tab(icon: Icon(Icons.fiber_manual_record, color: currentIndex == 0 ? Colors.red.shade400 : null), text: 'Recording'),
              const Tab(icon: Icon(Icons.videocam_off), text: 'Offline'),
              Tab(icon: Icon(Icons.pause, color: currentIndex == 2 ? Colors.amber : null), text: 'Paused'), //
            ],
          );
        },
      ),
    );
  }
}
