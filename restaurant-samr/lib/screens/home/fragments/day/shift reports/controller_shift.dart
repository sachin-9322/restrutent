


import 'package:get/get.dart';
import 'package:splash_screen_03/model/EntityShiftReport.dart';
import 'package:splash_screen_03/model/enity_day_report.dart';
import 'package:splash_screen_03/repository/day_repo.dart';
import 'package:splash_screen_03/repository/shift_report_repo.dart';

class ShiftController extends GetxController {
  final repo = Get.find<ShiftReportRepo>();
  final dayRepo = Get.find<DayReportRepo>();

  final currentShift = Rxn<EntityShiftReport>();
  final currentDay = Rxn<EntityDayReport>();

  @override
  void onInit() {
    super.onInit();
    currentDay.value = dayRepo.currentOpen();
    if (currentDay.value != null) {
      currentShift.value = repo.currentOpenShift(currentDay.value!.id);
    }
  }

  bool get hasOpenDay => currentDay.value != null;
  bool get hasOpenShift => currentShift.value != null;

  Future<void> refreshAll() async {
    currentDay.value = dayRepo.currentOpen();
    if (currentDay.value != null) {
      currentShift.value = repo.currentOpenShift(currentDay.value!.id);
    } else {
      currentShift.value = null;
    }
  }
}
