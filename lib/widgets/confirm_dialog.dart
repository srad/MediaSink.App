import 'package:flutter/material.dart';

extension DialogExtensions on BuildContext {
  Future<void> confirm({
    required Widget title,
    required Widget content,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    // Capture the context early to prevent issues with async gaps
    final contextSafe = this; // Capture context before the async operation

    await showDialog(
      context: contextSafe,
      builder: (context) {
        return AlertDialog(
          title: title,
          content: content,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(contextSafe, 'Cancel');
                onCancel?.call();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(contextSafe, 'OK');
                onConfirm?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
