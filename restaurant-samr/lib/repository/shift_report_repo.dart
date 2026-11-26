import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/EntityShiftReport.dart';
import 'package:splash_screen_03/objectbox.g.dart';

class ShiftReportRepo {
  Box<EntityShiftReport> get box => Get.find<Box<EntityShiftReport>>();

  // ---------------------------------------------------------
  // Get currently open shift for a specific Day
  // ---------------------------------------------------------
  EntityShiftReport? currentOpenShift(int dayId) {
    final q = box
        .query(
            EntityShiftReport_.dayId.equals(dayId) &
            EntityShiftReport_.isShiftOpen.equals(true))
        .build();
    final shift = q.findFirst();
    q.close();
    return shift;
  }

  // ---------------------------------------------------------
  // Start a new shift
  // ---------------------------------------------------------
  EntityShiftReport startShift({
    required int dayId,
    required String username,
    required double openingCash,
    String? comments,
  }) {
    final shift = EntityShiftReport(
      dayId: dayId,
      username: username,
      startedAt: DateTime.now(),
      openingCash: openingCash,
      comments: comments,
      isShiftOpen: true,
    );

    box.put(shift);
    return shift;
  }

  // ---------------------------------------------------------
  // Close shift
  // ---------------------------------------------------------
  EntityShiftReport? closeShift({
    required int shiftId,
    required double closingCash,
    String? comments,
  }) {
    final shift = box.get(shiftId);
    if (shift == null) return null;

    shift.endedAt = DateTime.now();
    shift.closingCash = closingCash;
    shift.comments = comments;
    shift.isShiftOpen = false;

    box.put(shift);
    return shift;
  }

  // ---------------------------------------------------------
  // All shifts of a day
  // ---------------------------------------------------------
  List<EntityShiftReport> shiftsOfDay(int dayId) {
    final q = box.query(EntityShiftReport_.dayId.equals(dayId)).build();
    final list = q.find();
    q.close();
    return list;
  }
}
