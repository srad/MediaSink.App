import 'package:flutter/material.dart';

class ChannelSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String)? onSearchChanged;
  final Function(bool)? onFav;
  final Function()? onAdd;

  const ChannelSearchAppBar({super.key, this.onSearchChanged, this.onFav, this.onAdd});

  @override
  _ChannelSearchAppBarState createState() => _ChannelSearchAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight); // Standard AppBar height
}

class _ChannelSearchAppBarState extends State<ChannelSearchAppBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _showClearIcon = false;
  bool _fav = false;

  @override
  void initState() {
    super.initState();
    // Adding listener to the TextEditingController to track text changes
    _searchController.addListener(() {
      if (widget.onSearchChanged != null) {
        widget.onSearchChanged!(_searchController.text);
      }
      setState(() {
        _showClearIcon = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Search channels...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.white70)), style: TextStyle(color: Colors.white), cursorColor: Colors.white),
      actions: [
        if (_showClearIcon)
          IconButton(
            icon: Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              _searchController.clear();
            },
          ),
        IconButton(
          onPressed: () {
            setState(() {
              _fav = !_fav;
            });
            if (widget.onFav != null) {
              widget.onFav!(_fav);
            }
          },
          icon: Icon(Icons.favorite, color: _fav ? Colors.pink : null),
        ),
        IconButton(
          onPressed: () {
            if (widget.onAdd != null) {
              widget.onAdd!();
            }
          },
          icon: Icon(Icons.add),
        ),
      ],
    );
  }
}
