import 'package:flutter/material.dart';

enum SnackbarType { info, success, error }

class ModalSnackbar {
  final BuildContext context;
  const ModalSnackbar(this.context);

  void show(String message, {SnackbarType type = SnackbarType.info}) {
    final colors = _getColors(type);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIcon(type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: colors,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: type == SnackbarType.error ? 4 : 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void showSuccess(String message) => show(message, type: SnackbarType.success);
  void showError(String message) => show(message, type: SnackbarType.error);

  Color _getColors(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Colors.green.shade600;
      case SnackbarType.error:
        return Colors.red.shade600;
      case SnackbarType.info:
        return Colors.blueGrey.shade700;
    }
  }

  IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.info:
        return Icons.info;
    }
  }
}
