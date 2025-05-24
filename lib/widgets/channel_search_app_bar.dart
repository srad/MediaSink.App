import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediasink_app/api/rest_client.dart';
import 'package:mediasink_app/factories/rest_client_factory.dart';
import 'package:mediasink_app/widgets/confirm_dialog.dart';
import 'package:mediasink_app/widgets/polling_widget.dart';
import 'package:provider/provider.dart';

class ChannelSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String)? onSearchChanged;
  final Function(bool)? onFav;
  final Function()? onAdd;
  final bool isFav;

  const ChannelSearchAppBar({super.key, this.onSearchChanged, this.onFav, this.onAdd, required this.isFav});

  @override
  _ChannelSearchAppBarState createState() => _ChannelSearchAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight); // Standard AppBar height
}

class _ChannelSearchAppBarState extends State<ChannelSearchAppBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _showClearIcon = false;
  Timer? _debounce;

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (widget.onSearchChanged != null) {
        widget.onSearchChanged!(_searchController.text);
      }
    });

    setState(() {
      _showClearIcon = _searchController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color.alphaBlend(Colors.white.withValues(alpha: 0.9), Theme.of(context).primaryColor);
    final factory = context.read<RestClientFactory>();

    return AppBar(
      automaticallyImplyLeading: false,
      title: TextField(
        autofocus: false,
        controller: _searchController,
        decoration: InputDecoration(hintText: 'Search channels...', border: InputBorder.none, hintStyle: TextStyle(color: color)),
        style: TextStyle(color: color),
        cursorColor: color, //
      ),
      actions: [
        FutureBuilder(
          future: factory.create(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return CircularProgressIndicator();
            }
            final client = snapshot.data!;

            return PollingBuilder(
              pollingFunction: client!.recorder.getRecorder,
              pollingInterval: const Duration(seconds: 3),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  // Show a loading indicator only if there's no previous data to display
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center);
                }
                if (snapshot.hasData) {
                  final isRecording = snapshot.data?.isRecording ?? false;

                  return IconButton(
                    onPressed: () async {
                      await context.confirm(
                        title: Text('Confirm'),
                        content: Text('${isRecording ? 'Pause' : 'Resume'} recording?'),
                        onConfirm: () async {
                          if (isRecording) {
                            await client?.recorder.postRecorderPause();
                          } else {
                            await client?.recorder.postRecorderResume();
                          }
                        },
                      );
                    },
                    icon: Icon(snapshot.data?.isRecording ?? false ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: snapshot.data?.isRecording ?? false ? Colors.orangeAccent : Colors.lightGreen, size: 30),
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            );
          },
        ),
        if (_showClearIcon)
          IconButton(
            icon: Icon(Icons.clear, color: color),
            onPressed: () {
              _searchController.clear();
            },
          ),
        IconButton(
          onPressed: () {
            setState(() {
              widget.onFav?.call(!widget.isFav);
            });
          },
          icon: Icon(widget.isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded, color: widget.isFav ? Colors.pink : color),
        ),
        IconButton(
          onPressed: () {
            if (widget.onAdd != null) {
              widget.onAdd!();
            }
          },
          icon: Icon(Icons.add_rounded, color: color),
        ),
      ],
    );
  }
}
