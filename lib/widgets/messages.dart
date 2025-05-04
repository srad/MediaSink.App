import 'package:flutter/material.dart';

void snackOk(BuildContext context, Widget content) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: content, backgroundColor: Colors.lightGreen.shade500, duration: Duration(seconds: 1)));
}

void snackErr(BuildContext context, Widget content) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: content, backgroundColor: Colors.red.shade300));
}
