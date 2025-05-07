import 'package:flutter/material.dart';

class DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool iconOnly;
  double iconSize;

  DeleteButton({super.key, required this.onPressed, this.iconOnly = false, this.iconSize = 18});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.delete_forever_rounded, size: iconSize, color: Colors.red.shade400);

    if (iconOnly) {
      return IconButton(
        icon: icon,
        tooltip: 'Delete',
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(), //
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: const Padding(
        padding: EdgeInsets.only(right: 6),
        child: Text(
          'Delete',
          style: TextStyle(fontSize: 14), //
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero, //
      ),
    );
  }
}
