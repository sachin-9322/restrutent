import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Optional: wire this in MaterialApp to use showMiniSnackGlobal anywhere.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum MiniSnackType { info, success, error, warning }

Color _accentForType(MiniSnackType type) {
  switch (type) {
    case MiniSnackType.success:
      return Colors.green;
    case MiniSnackType.error:
      return Colors.red;
    case MiniSnackType.warning:
      return Colors.orange;
    case MiniSnackType.info:
    default:
      return Colors.blue;
  }
}

IconData _iconForType(MiniSnackType type) {
  switch (type) {
    case MiniSnackType.success:
      return Icons.check_circle_outline;
    case MiniSnackType.error:
      return Icons.error_outline;
    case MiniSnackType.warning:
      return Icons.warning_amber_outlined;
    case MiniSnackType.info:
    default:
      return Icons.info_outline;
  }
}

/// Compact bottom-center snackbar using margin only (no width to avoid assertion).
void showMiniSnack(
  BuildContext context,
  String title,
  String message, {
  MiniSnackType type = MiniSnackType.info,
  Duration duration = const Duration(seconds: 2),
  double? maxWidth, // desired max width (e.g. 320)
  double bottomGap = 16,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  final accent = _accentForType(type);
  final icon = _iconForType(type);

  final screenW = MediaQuery.of(context).size.width;

  // Compute a compact width by using symmetric horizontal margins.
  // Keep at least 12px margin each side to avoid clipping.
  final desired = maxWidth ?? math.min(screenW * 0.9, 340.0);
  final width = math.min(desired, screenW - 24.0);
  final horizontalGap = (screenW - width) / 2;

  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      // Important: DO NOT set `width` when using `margin`, Flutter asserts on that.
      margin: EdgeInsets.only(
        left: horizontalGap,
        right: horizontalGap,
        bottom: bottomGap,
      ),
      elevation: 2,
      duration: duration,
      backgroundColor: scheme.surface,
      dismissDirection: DismissDirection.horizontal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withOpacity(0.35)),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Global convenience (no BuildContext needed). Requires `rootScaffoldMessengerKey`
/// to be set in MaterialApp. If context is available, it delegates to showMiniSnack.
void showMiniSnackGlobal(
  String title,
  String message, {
  MiniSnackType type = MiniSnackType.info,
  Duration duration = const Duration(seconds: 2),
  double? maxWidth,
  double bottomGap = 16,
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  final ctx = rootScaffoldMessengerKey.currentContext;

  if (messenger == null) return;

  // Use context for theming/sizing if available, otherwise fallbacks
  final theme = ctx != null ? Theme.of(ctx) : ThemeData.light();
  final scheme = theme.colorScheme;
  final screenW = ctx != null ? MediaQuery.of(ctx).size.width : 400.0;

  final accent = _accentForType(type);
  final icon = _iconForType(type);

  // Compute layout
  final desired = maxWidth ?? math.min(screenW * 0.9, 340.0);
  final width = math.min(desired, screenW - 24.0);
  final horizontalGap = (screenW - width) / 2;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      // Use computed margins if context was available, else default
      margin: ctx != null
          ? EdgeInsets.only(
              left: horizontalGap,
              right: horizontalGap,
              bottom: bottomGap,
            )
          : const EdgeInsets.all(12),
      elevation: 2,
      duration: duration,
      backgroundColor: scheme.surface,
      dismissDirection: DismissDirection.horizontal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withOpacity(0.35)),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
