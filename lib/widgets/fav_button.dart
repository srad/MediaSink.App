import 'package:flutter/material.dart';

class FavButton extends StatelessWidget {
  final bool isFav;
  final bool isBusy;
  final VoidCallback onPressed;
  final double iconSize;

  const FavButton({
    super.key,
    required this.isFav,
    required this.onPressed,
    this.isBusy = false,
    this.iconSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return IconButton(
        onPressed: () {}, // disabled
        icon: SizedBox(
          height: iconSize,
          width: iconSize,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            child: child,
          );
        },
        child: Icon(
          Icons.favorite_rounded,
          key: ValueKey<bool>(isFav),
          color: isFav ? Colors.pink : Colors.grey,
          size: iconSize,
        ),
      ),
    );
  }
}