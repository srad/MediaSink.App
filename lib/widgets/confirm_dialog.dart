import 'package:flutter/material.dart';

Future<void> confirm({required BuildContext context, required Widget title, required Widget content, Function? onConfirm, Function? onCancel}) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title,
        content: content,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Cancel');
              if (onCancel != null) onCancel();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, 'OK');
              if (onConfirm != null) onConfirm();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
