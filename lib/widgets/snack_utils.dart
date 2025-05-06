import 'package:flutter/material.dart';

extension SnackBarExtensions on ScaffoldMessengerState {
  void showOk(String message) {
    showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.lightGreen.shade600,
        duration: const Duration(seconds: 1), //
      ),
    );
  }

  void showError(String message) {
    showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade300, //
      ),
    );
  }
}
