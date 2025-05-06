import 'package:flutter/material.dart';

class PauseButton extends StatelessWidget {
  final bool isPaused;
  final bool isBusy;
  final VoidCallback onPressed;
  final double iconSize;

  const PauseButton({
    super.key,
    required this.isPaused,
    required this.onPressed,
    this.isBusy = false,
    this.iconSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return IconButton(
        onPressed: () {}, // disabled during busy state
        icon: SizedBox(
          height: iconSize,
          width: iconSize,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      icon: Icon(
        isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled_rounded,
        color: isPaused ? Colors.lightGreen : Colors.amber.shade700,
        size: iconSize,
      ),
      onPressed: onPressed,
    );
  }
}