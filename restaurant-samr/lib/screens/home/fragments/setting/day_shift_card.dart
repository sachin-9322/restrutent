import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:splash_screen_03/model/enity_day_report.dart';
import 'package:splash_screen_03/model/EntityShiftReport.dart';


import 'package:splash_screen_03/screens/home/fragments/day/day_report.dart';
import 'package:splash_screen_03/screens/home/fragments/day/shift%20reports/close_day.dart';
import 'package:splash_screen_03/screens/home/fragments/day/shift%20reports/close_shift.dart';



/// ==========================
///   DAY STATUS CARD
/// ==========================
Widget dayStatusCard(BuildContext context, {required EntityDayReport? open}) {
  final theme = Theme.of(context);
  final df = DateFormat('yyyy-MM-dd hh:mm:ss a');

  final isOpen = open != null;

  final title = isOpen ? 'Close Day' : 'Start Day';
  final subtitle = isOpen
      ? 'Started At: ${df.format(open!.openedAt)}'
      : 'No active day';

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.meeting_room_outlined,
          size: 42, color: theme.colorScheme.secondary),
      const SizedBox(height: 10),
      Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}


/// ==========================
///   SHIFT STATUS CARD
/// ==========================
Widget shiftStatusCard(BuildContext context, {required EntityShiftReport? shift}) {
  final theme = Theme.of(context);
  final df = DateFormat('yyyy-MM-dd hh:mm:ss a');

  final isOpen = shift != null;

  final title = isOpen ? 'Close Shift' : 'Start Shift';
  final subtitle = isOpen
      ? 'Started At: ${df.format(shift!.startedAt)}'
      : 'No active shift';

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.timelapse_rounded,
          size: 42, color: theme.colorScheme.secondary),
      const SizedBox(height: 10),
      Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}


/// ==========================
///   DAY START / CLOSE BUTTONS
/// ==========================
class DayStartCloseButtons extends StatelessWidget {
  const DayStartCloseButtons({
    super.key,
    this.onAfterAction,
    this.showStart = true,
  });

  final bool showStart;
  final Future<void> Function()? onAfterAction;

  @override
  Widget build(BuildContext context) {
    final dayCtrl = Get.find<DayStatusController>();
    final theme = Theme.of(context);

    return Obx(() {
      final open = dayCtrl.openReport.value;
      final isDayOpen = open != null;

      final buttons = <Widget>[];

      if (showStart && !isDayOpen) {
        buttons.add(
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Day & Shift'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ShiftStartDialog.show();
              await dayCtrl.refreshOpen();
              if (onAfterAction != null) await onAfterAction!();
            },
          ),
        );
        buttons.add(const SizedBox(width: 12));
      }

      if (isDayOpen) {
        buttons.add(
          ElevatedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Close Day & Shift'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              backgroundColor: theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await CloseShiftDialog.show();
              await dayCtrl.refreshOpen();
              if (onAfterAction != null) await onAfterAction!();
            },
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      );
    });
  }
}


/// ==========================
///   SHIFT START / CLOSE BUTTONS
/// ==========================
class ShiftStartCloseButtons extends StatelessWidget {
  const ShiftStartCloseButtons({super.key, this.onAfterAction});

  final Future<void> Function()? onAfterAction;

  @override
  Widget build(BuildContext context) {
    final shiftCtrl = Get.find<ShiftController>();
    final theme = Theme.of(context);

    return Obx(() {
      final shift = shiftCtrl.currentShift.value;
      final shiftIsOpen = shift != null;

      final buttons = <Widget>[];

      if (!shiftIsOpen) {
        buttons.add(
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Shift'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ShiftStartDialog.show();
              await shiftCtrl.refreshAll();
              if (onAfterAction != null) await onAfterAction!();
            },
          ),
        );
        buttons.add(const SizedBox(width: 12));
      }

      if (shiftIsOpen) {
        buttons.add(
          ElevatedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Close Shift'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              backgroundColor: theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ShiftCloseDialog.show();
              await shiftCtrl.refreshAll();
              if (onAfterAction != null) await onAfterAction!();
            },
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      );
    });
  }
}
