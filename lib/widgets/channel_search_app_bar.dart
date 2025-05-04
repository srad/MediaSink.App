import 'dart:async';
import 'package:flutter/material.dart';

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

    return AppBar(
      automaticallyImplyLeading: false,
      title: TextField(autofocus: false, controller: _searchController, decoration: InputDecoration(hintText: 'Search channels...', border: InputBorder.none, hintStyle: TextStyle(color: color)), style: TextStyle(color: color), cursorColor: color),
      actions: [
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
          icon: Icon(widget.isFav ? Icons.favorite : Icons.favorite_outline, color: widget.isFav ? Colors.pink : color),
        ),
        IconButton(
          onPressed: () {
            if (widget.onAdd != null) {
              widget.onAdd!();
            }
          },
          icon: Icon(Icons.add_circle, color: color),
        ),
      ],
    );
  }
}
