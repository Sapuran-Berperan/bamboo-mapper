import 'package:flutter/material.dart';

class ModalSnackbar {
  final BuildContext context;
  const ModalSnackbar(this.context);

  void show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
