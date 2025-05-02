import 'dart:async';
import 'package:flutter/material.dart';

class RecordingIndicator extends StatefulWidget {
  const RecordingIndicator({super.key});

  @override
  _RecordingIndicatorState createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator> {
  bool _visible = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _visible = !_visible;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 800),
      child: Icon(Icons.fiber_manual_record, color: Colors.red, size: 30),
    );
  }
}
