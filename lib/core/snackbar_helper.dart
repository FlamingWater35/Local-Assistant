import 'package:flutter/material.dart';

void showSuccessSnackBar(BuildContext context, String message) {
  _showSnackBar(
    context,
    message: message,
    backgroundColor: Colors.green.shade700,
    icon: Icons.check_circle_outline,
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  _showSnackBar(
    context,
    message: message,
    backgroundColor: Colors.red.shade800,
    icon: Icons.error_outline,
  );
}

void showInfoSnackBar(BuildContext context, String message) {
  _showSnackBar(
    context,
    message: message,
    backgroundColor: Colors.blue.shade800,
    icon: Icons.info_outline,
  );
}

void _showSnackBar(
  BuildContext context, {
  required String message,
  required Color backgroundColor,
  required IconData icon,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final contentColor = Colors.white;

  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      dismissDirection: DismissDirection.horizontal,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: contentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: contentColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              messenger.hideCurrentSnackBar();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: contentColor, size: 16),
            ),
          ),
        ],
      ),
    ),
  );
}
