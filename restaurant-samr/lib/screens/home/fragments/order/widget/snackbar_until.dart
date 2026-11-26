import 'package:flutter/material.dart';

class SnackbarUtil {
  // Success
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool floating = true,
  }) {
    _show(
      context,
      message,
      title: title,
      icon: Icons.check_circle_rounded,
      backgroundColor: Colors.green.shade600,
      duration: duration,
      action: action,
      floating: floating,
    );
  }

  // Error
  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool floating = true,
  }) {
    _show(
      context,
      message,
      title: title,
      icon: Icons.error_rounded,
      backgroundColor: Colors.red.shade600,
      duration: duration,
      action: action,
      floating: floating,
    );
  }

  // Internal show
  static void _show(
    BuildContext context,
    String message, {
    String? title,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool floating = true,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      // Fallback if no ScaffoldMessenger found in the widget tree
      debugPrint('SnackbarUtil: No ScaffoldMessenger found for the given context.');
      return;
    }

    final onColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: _SnackContent(
          icon: icon,
          title: title,
          message: message,
          color: onColor,
        ),
        backgroundColor: backgroundColor,
        behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        margin: floating ? const EdgeInsets.all(16) : null,
        shape: floating
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            : null,
        duration: duration,
        action: action,
      ),
    );
  }
}

class _SnackContent extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final Color color;

  const _SnackContent({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                message,
                style: TextStyle(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}