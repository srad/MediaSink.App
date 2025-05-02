import 'package:flutter/cupertino.dart';

class SlideFromRight extends StatefulWidget {
  final Widget child;
  const SlideFromRight({super.key, required this.child});

  @override
  _SlideFromRightState createState() => _SlideFromRightState();
}

class _SlideFromRightState extends State<SlideFromRight> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 300), vsync: this)..forward();
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // from right
      end: Offset.zero,              // to original position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInExpo));
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offsetAnimation, child: widget.child);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
