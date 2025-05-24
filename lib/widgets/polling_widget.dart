import 'dart:async';
import 'package:flutter/material.dart';

// Callback to be executed for polling, should return a Future of type T
typedef PollingFunction<T> = Future<T> Function();

// Builder that receives the BuildContext and the latest snapshot of data (or error)
typedef PollingWidgetBuilder<T> = Widget Function(BuildContext context, AsyncSnapshot<T> snapshot);

class PollingBuilder<T> extends StatefulWidget {
  final PollingFunction<T> pollingFunction;
  final PollingWidgetBuilder<T> builder;
  final Duration pollingInterval;
  final T? initialData; // Optional initial data to display before first poll

  const PollingBuilder({
    super.key,
    required this.pollingFunction,
    required this.builder,
    this.pollingInterval = const Duration(seconds: 5), // Default polling interval
    this.initialData,
  });

  @override
  State<PollingBuilder<T>> createState() => _PollingBuilderState<T>();
}

class _PollingBuilderState<T> extends State<PollingBuilder<T>> {
  Timer? _pollingTimer;
  AsyncSnapshot<T> _snapshot; // Holds the current state of the future

  _PollingBuilderState() : _snapshot = AsyncSnapshot<T>.nothing(); // Initial empty state

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, widget.initialData as T);
    }
    _startPolling();
  }

  @override
  void didUpdateWidget(PollingBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pollingFunction != oldWidget.pollingFunction ||
        widget.pollingInterval != oldWidget.pollingInterval) {
      // If the function or interval changes, restart polling with new settings
      _stopPolling();
      _startPolling();
    }
    // Note: We don't automatically re-fetch if only the builder changes,
    // as the data itself hasn't changed. The builder will be called by Flutter.
  }

  void _startPolling() {
    // Ensure any existing timer is cancelled before starting a new one
    _pollingTimer?.cancel();

    // Initial fetch immediately
    _executePoll();

    // Start periodic polling
    _pollingTimer = Timer.periodic(widget.pollingInterval, (timer) {
      _executePoll();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _executePoll() async {
    if (!mounted) return;

    // Indicate loading state for the current poll
    // Only update to loading if we are not already done with some data
    // This provides a smoother experience if data updates quickly
    if (_snapshot.connectionState != ConnectionState.done || _snapshot.data == null) {
      setState(() {
        _snapshot = _snapshot.inState(ConnectionState.waiting);
      });
    }


    try {
      final T result = await widget.pollingFunction();
      if (mounted) {
        setState(() {
          _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, result);
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
        });
      }
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _snapshot);
  }
}