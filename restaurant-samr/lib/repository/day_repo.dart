import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/enity_day_report.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/repository/shift_report_repo.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';

class DayReportRepo {
  DayReportRepo();

  Box<EntityDayReport> get dayBox => Get.find<Box<EntityDayReport>>();

  /// Determine next invoice start: last closed invoiceEnd + 1 or 1001
  int nextInvoiceStart() {
    final last = lastClosed();
    if (last == null) return 1001;
    return (last.invoiceEnd ?? 1000) + 1;
  }

  Future<EntityDayReport> startDay({
    required String username,
    String? comments,
    required List<EntityDenominationCount> denomSnapshot,
    String? currencyCode,
    String? currencySymbol,
    String? currencyLocale,
    int? invoiceStart, // optional - repo can compute
    int? invoiceEnd,
  }) async {
    final openingCash =
        denomSnapshot.fold<double>(0.0, (sum, e) => sum + e.amount);

    final computedStart = invoiceStart ?? nextInvoiceStart();
    final computedEnd = invoiceEnd ?? computedStart; // initially same

    final report = EntityDayReport(
      username: username,
      openedAt: DateTime.now(),
      openingComments:
          (comments ?? '').trim().isEmpty ? null : comments!.trim(),
      openingCash: openingCash,
      isOpen: true,
      invoiceStart: computedStart,
      invoiceEnd: computedEnd,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      currencyLocale: currencyLocale,
    );

    report.denomCounts.addAll(denomSnapshot);

    dayBox.put(report);
    report.denomCounts.applyToDb();

    return report;
  }
bool hasOpenShift(int dayId) {
  final shiftRepo = Get.find<ShiftReportRepo>();
  return shiftRepo.currentOpenShift(dayId) != null;
}

  EntityDayReport? currentOpen() {
    final q = dayBox
        .query(EntityDayReport_.isOpen.equals(true))
        .order(EntityDayReport_.openedAt, flags: Order.descending)
        .build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  EntityDayReport? closeDay({
    required int dayId,
    String? closingComments,
    double? closingCash,
    double? totalSales,
    double? totalRefunds,
    double? totalExpenses,
  }) {
    final report = dayBox.get(dayId);
    if (report == null) return null;

    report.closedAt = DateTime.now();
    report.closingComments =
        (closingComments ?? '').trim().isEmpty ? null : closingComments!.trim();
    report.closingCash = closingCash;
    report.totalSales = totalSales ?? report.totalSales;
    report.totalRefunds = totalRefunds ?? report.totalRefunds;
    report.totalExpenses = totalExpenses ?? report.totalExpenses;
    report.isOpen = false;

    dayBox.put(report);
    return report;
  }

  EntityDayReport? closeOpenDay({
    String? closingComments,
    required double closingCash,
    double? totalSales,
    double? totalRefunds,
    double? totalExpenses,
  }) {
    final open = currentOpen();
    if (open == null) return null;
    return closeDay(
      dayId: open.id,
      closingComments: closingComments,
      closingCash: closingCash,
      totalSales: totalSales,
      totalRefunds: totalRefunds,
      totalExpenses: totalExpenses,
    );
  }

  EntityDayReport? lastClosed() {
    final q = dayBox
        .query(EntityDayReport_.closedAt.notNull())
        .order(EntityDayReport_.closedAt, flags: Order.descending)
        .build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  List<EntityDayReport> allDesc() {
    final q = dayBox
        .query()
        .order(EntityDayReport_.openedAt, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  List<String> previousDayHistoryLines() {
    final r = lastClosed();
    if (r == null) return [];

    final df = DateFormat('dd/MM/yyyy hh:mm a');

    ControllerSetting? settings;
    if (Get.isRegistered<ControllerSetting>()) {
      settings = Get.find<ControllerSetting>();
    }

    final locale = r.currencyLocale ?? settings?.currLocale ?? 'en_US';
    final symbol =
        (r.currencySymbol ?? settings?.currSymbol ?? (r.currencyCode ?? '')).trim();
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: symbol.isEmpty ? '' : '$symbol ',
    );

    return [
      'Opened: ${df.format(r.openedAt)}',
      'Opening Cash: ${fmt.format(r.openingCash)}',
      if (r.totalSales != null) 'Total Sales: ${fmt.format(r.totalSales!)}',
      if (r.totalRefunds != null) 'Refunds: ${fmt.format(r.totalRefunds!)}',
      if (r.totalExpenses != null) 'Expenses: ${fmt.format(r.totalExpenses!)}',
      if (r.closingCash != null) 'Closing Cash: ${fmt.format(r.closingCash!)}',
      if (r.closedAt != null) 'Closed: ${df.format(r.closedAt!)}',
    ];
  }
}
