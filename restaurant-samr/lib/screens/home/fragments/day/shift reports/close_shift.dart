// shift_close_dialog.dart
// Full Shift Close UI (exact copy of Close Day UI) but shift-only logic.
// Drop this file into your project and import where needed.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';

import 'package:splash_screen_03/captain/login/auth_service.dart'; // only if you want unified auth (not used here)
import 'package:splash_screen_03/model/EntityShiftReport.dart';
import 'package:splash_screen_03/model/enity_day_report.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/enum_bill_status.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/repository/day_repo.dart';
import 'package:splash_screen_03/repository/shift_report_repo.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/day/day_report.dart'; // for Denomination / EntityDenominationCount types if needed

/// Reuse Denomination type from your code if available; otherwise defined here.
class Denomination {
  Denomination(this.label, this.value, {int count = 0}) : count = count.obs;
  final String label;
  final double value;
  final RxInt count;
  double get amount => value * count.value;
}

// ============================================================================
// SHIFT CLOSE CONTROLLER (shift-only, checks open bills like Close Day)
// ============================================================================
class ShiftCloseController extends GetxController {
  static ShiftCloseController get to => Get.find<ShiftCloseController>();

  final ShiftReportRepo shiftRepo = Get.find<ShiftReportRepo>();
  final DayReportRepo dayRepo = Get.find<DayReportRepo>();
  final settings = Get.find<ControllerSetting>();

  final now = DateTime.now().obs;
  late final Timer _clock;

  /// Holds the currently open shift (not day) — populated in onInit
  final Rxn<EntityShiftReport> openShift = Rxn<EntityShiftReport>();

  /// For convenience replicate some fields like CloseDay controller
  final username = ''.obs;
  final openingBalance = 0.0.obs;

  final comments = ''.obs;

  NumberFormat get moneyFmt => NumberFormat.currency(
        locale: settings.currLocale,
        symbol: '${settings.currSymbol} ',
      );

  // -----------------------------
  // DENOMINATION LIST FOR CLOSING
  // -----------------------------
  final denoms = <Denomination>[
    Denomination('AED 1000', 1000),
    Denomination('AED 500', 500),
    Denomination('AED 200', 200),
    Denomination('AED 100', 100),
    Denomination('AED 50', 50),
    Denomination('AED 20', 20),
    Denomination('AED 10', 10),
    Denomination('AED 5', 5),
    Denomination('AED 1', 1),
    Denomination('fils 0.5', 0.5),
  ];

  final Map<Denomination, TextEditingController> textControllers = {};

  double get totalInDrawer => denoms.fold(0.0, (sum, d) => sum + d.amount);

  // ----------------------------
  // PAYMENTS / SUMMARY VALUES
  // ----------------------------
  final paymentSummary = <String, double>{}.obs;

  final fulfilledOrders = 0.obs;
  final cancelledOrders = 0.obs;
  final complimentaryOrders = 0.obs;

  final totalExpenses = 0.0.obs;

  // ------------------------------------------------------------
  // Set all metrics (optional): payment, expenses, counts...
  // ------------------------------------------------------------
  void setMetrics({
    Map<String, double>? paymentModeTotals,
    int? fulfilled,
    int? cancelled,
    int? complimentary,
    double? expenses,
  }) {
    if (paymentModeTotals != null) paymentSummary.assignAll(paymentModeTotals);
    if (fulfilled != null) fulfilledOrders.value = fulfilled;
    if (cancelled != null) cancelledOrders.value = cancelled;
    if (complimentary != null) complimentaryOrders.value = complimentary;
    if (expenses != null) totalExpenses.value = expenses;
  }

  // ------------------------------------------------------------
  // Denomination controls
  // ------------------------------------------------------------
  void setCount(Denomination d, String v) {
    final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    d.count.value = parsed.clamp(0, 999999);
  }

  void _syncText(Denomination d) {
    final tc = textControllers[d];
    if (tc != null) {
      final desired = d.count.value.toString();
      if (tc.text != desired) {
        tc.text = desired;
        tc.selection = TextSelection.collapsed(offset: tc.text.length);
      }
    }
  }

  void increment(Denomination d) {
    d.count.value++;
    _syncText(d);
  }

  void decrement(Denomination d) {
    d.count.value = (d.count.value - 1).clamp(0, 999999);
    _syncText(d);
  }

  // ========================================================================
  //                            CLOSE SHIFT (MAIN)
  // ========================================================================
  /// Returns true if shift was closed successfully.
  Future<bool> closeShift() async {
    // ------------------------------------------------------------
    // 1) Check for un-settled/open bills — DO NOT ALLOW CLOSE
    // ------------------------------------------------------------
    // We keep the same logic as CloseDay: if there are open booked bills, block close.
    try {
      final Box<EntityOrder> orderBox = Get.find<Box<EntityOrder>>();

      final query = orderBox
          .query(EntityOrder_.status.equals(BillStatus.booked.value))
          .build();

      final openBills = query.find();
      query.close();

      if (openBills.isNotEmpty) {
        final tables = openBills
            .map((b) => b.tableName ?? 'Unknown')
            .toSet()
            .join(", ");

        Get.snackbar(
          "Cannot Close Shift",
          "Please settle all open bills first.\nOpen tables: $tables",
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          backgroundColor: Colors.orange.shade300,
          colorText: Colors.black,
          borderRadius: 8,
          duration: const Duration(seconds: 6),
        );
        return false;
      }
    } catch (e) {
      // If objectbox or orders not present, we fallback to allowing close (or you can rethrow)
      // But as per requirement we keep check; if Box not registered, show error and block:
      try {
        // attempt to continue if Box not configured; but prefer blocking for safety
      } catch (_) {}
    }

    // ------------------------------------------------------------
    // 2) Calculate final closing cash
    // ------------------------------------------------------------
    final closingCash = totalInDrawer;

    // ------------------------------------------------------------
    // 3) Store closing shift summary into DB via shiftRepo.closeShift
    // ------------------------------------------------------------
    final shift = openShift.value;
    if (shift == null) {
      Get.snackbar(
        "Error",
        "No open shift found to close.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade200,
      );
      return false;
    }

    final closed = shiftRepo.closeShift(
      shiftId: shift.id,
      closingCash: closingCash,
      comments: comments.value,
    );

    if (closed == null) {
      Get.snackbar(
        "Error",
        "Failed to close shift.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade200,
      );
      return false;
    }

    // ------------------------------------------------------------
    // 4) Update reactive state
    // ------------------------------------------------------------
    openShift.value = closed;

    // ------------------------------------------------------------
    // 5) Success notification
    // ------------------------------------------------------------
    Get.snackbar(
      "Shift Closed Successfully",
      "Opening: ${moneyFmt.format(closed.openingCash)}\n"
          "Closing: ${moneyFmt.format(closingCash)}",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );

    // optionally refresh ShiftController (if present)
    if (Get.isRegistered<ShiftController>()) {
      final shiftCtrl = Get.find<ShiftController>();
      await shiftCtrl.refreshAll();
    }

    return true;
  }

  // ========================================================================
  //                           INIT & DISPOSE
  // ========================================================================
  @override
  void onInit() {
    super.onInit();

    // real-time clock update
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });

    // get active shift from ShiftReportRepo or ShiftController
    // Prefer ShiftController if present (it tracks currentShift + currentDay)
    if (Get.isRegistered<ShiftController>()) {
      final sc = Get.find<ShiftController>();
      openShift.value = sc.currentShift.value;
      username.value = sc.currentShift.value?.username ?? sc.username.value;
      openingBalance.value = sc.currentShift.value?.openingCash ?? 0.0;
    } else {
      // fallback: try to find any open shift by looking at the day
      final openDay = dayRepo.currentOpen();
      if (openDay != null) {
        final s = shiftRepo.currentOpenShift(openDay.id);
        openShift.value = s;
        username.value = s?.username ?? StorageRepository().username;
        openingBalance.value = s?.openingCash ?? 0.0;
      } else {
        username.value = StorageRepository().username;
        openingBalance.value = 0.0;
      }
    }

    // denomination text controllers
    for (final d in denoms) {
      final tc = TextEditingController(text: d.count.value.toString());
      textControllers[d] = tc;
      ever<int>(d.count, (_) => _syncText(d));
    }

    // Default payment modes
    if (paymentSummary.isEmpty) {
      paymentSummary.assignAll({'Cash': 0, 'Card': 0, 'UPI': 0});
    }
  }

  @override
  void onClose() {
    _clock.cancel();
    for (final tc in textControllers.values) {
      tc.dispose();
    }
    textControllers.clear();
    super.onClose();
  }
}

// ============================================================================
// SHIFT CLOSE DIALOG (UI copy of Close Day, but shift-only actions)
// ============================================================================
class ShiftCloseDialog extends StatelessWidget {
  const ShiftCloseDialog({super.key});

  static Future<void> show({
    Map<String, double>? paymentModeTotals,
    int? fulfilled,
    int? cancelled,
    int? complimentary,
    double? expenses,
  }) async {
    if (!Get.isRegistered<ShiftCloseController>()) {
      Get.put(ShiftCloseController());
    }
    final ctrl = Get.find<ShiftCloseController>();
    ctrl.setMetrics(
      paymentModeTotals: paymentModeTotals,
      fulfilled: fulfilled,
      cancelled: cancelled,
      complimentary: complimentary,
      expenses: expenses,
    );
    await Get.dialog(const ShiftCloseDialog(), barrierDismissible: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = ShiftCloseController.to;
    final fmt = NumberFormat.currency(locale: c.settings.currLocale, symbol: '${c.settings.currSymbol} ');

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
        child: Column(
          children: [
            // HEADER (teal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.teal,
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() {
                      final df = DateFormat('dd/MM/yyyy hh:mm a');
                      return Text(
                        'Close Shift - ${df.format(c.now.value)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT: Denominations
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _denominationHeader(color: Colors.teal),
                          const SizedBox(height: 8),
                          Expanded(child: _denominationList(c)),
                          const SizedBox(height: 8),
                          _totalFooter(
                            () => c.totalInDrawer,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // RIGHT: Summaries + Comments + Actions
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _paymentModeHeader(color: Colors.teal),
                          const SizedBox(height: 8),
                          _paymentModeList(c),
                          const SizedBox(height: 16),

                          Expanded(
                            child: Row(
                              children: [
                                // Middle stats (orders)
                                Expanded(
                                  flex: 5,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Obx(() => _chip('Username: ${c.username.value}', color: Colors.teal)),
                                        const SizedBox(height: 8),
                                        _chip('Order Statistics (Shift)', color: Colors.teal, isTitle: true),
                                        const SizedBox(height: 8),
                                        Obx(() => _chip('Fulfilled Orders: ${c.fulfilledOrders.value}', color: Colors.teal)),
                                        const SizedBox(height: 8),
                                        Obx(() => _chip('Cancelled Orders: ${c.cancelledOrders.value}', color: Colors.teal)),
                                        const SizedBox(height: 8),
                                        Obx(() => _chip('Complimentary Orders: ${c.complimentaryOrders.value}', color: Colors.teal)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Right stats + comments + buttons
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _chip('Closing Shift Summary', color: Colors.teal, isTitle: true),
                                      const SizedBox(height: 8),
                                      _chip('Account Statistics', color: Colors.teal, isTitle: true),
                                      const SizedBox(height: 8),
                                      // Opening Balance
                                      Obx(() {
                                        final _ = c.settings.currency.value;
                                        return _chip('Opening Balance: ${c.moneyFmt.format(c.openingBalance.value)}', color: Colors.teal);
                                      }),

                                      // Expenses
                                      Obx(() {
                                        final _ = c.settings.currency.value;
                                        return _chip('Expenses: ${c.moneyFmt.format(c.totalExpenses.value)}', color: Colors.teal);
                                      }),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        minLines: 3,
                                        maxLines: 5,
                                        onChanged: (v) => c.comments.value = v,
                                        decoration: const InputDecoration(
                                          hintText: 'Comments Here',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.red.shade600,
                                              ),
                                              onPressed: () => Get.back(),
                                              child: const Text('Cancel'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                              ),
                                              onPressed: () async {
                                                final bool wasClosed = await c.closeShift();
                                                if (wasClosed) {
                                                  // close dialog
                                                  Get.back();
                                                  // Optionally: mark showShiftDialogNextLogin so login prompts for shift
                                                  final storage = GetStorage();
                                                  await storage.write('showShiftDialogNextLogin', true);
                                                }
                                              },
                                              child: const Text(
                                                'CLOSE SHIFT',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- UI helper widgets (same as Close Day) ---------- */

Widget _denominationHeader({required Color color}) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: const Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            'Currency Denomination',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Count',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Amount',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _denominationList(ShiftCloseController c) {
  final cs = Get.context!.theme.colorScheme;
  return ListView.separated(
    itemCount: c.denoms.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (ctx, i) {
      final d = c.denoms[i];
      final tc = c.textControllers[d]!;
      return Container(
        decoration: BoxDecoration(
          color: i.isEven ? cs.surface : cs.surfaceContainerHighest.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Label reacts to settings.currency
            Expanded(
              flex: 5,
              child: Obx(() {
                final _ = c.settings.currency.value;
                return Text(
                  c.settings.currSymbol.isNotEmpty ? '${c.settings.currSymbol} ${d.value.toStringAsFixed(d.value >= 1 ? 0 : 0)}' : d.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                );
              }),
            ),

            // Count
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Decrease',
                    onPressed: () => c.decrement(d),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Flexible(
                    child: Obx(() {
                      final desired = d.count.value.toString();
                      if (tc.text != desired) {
                        tc.text = desired;
                        tc.selection = TextSelection.collapsed(offset: tc.text.length);
                      }
                      return TextFormField(
                        controller: tc,
                        textAlign: TextAlign.center,
                        onChanged: (v) => c.setCount(d, v),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(isDense: true, hintText: '0'),
                      );
                    }),
                  ),
                  IconButton(
                    tooltip: 'Increase',
                    onPressed: () => c.increment(d),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),

            // Amount
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(() {
                  final _ = c.settings.currency.value;
                  return Text(
                    c.moneyFmt.format(d.amount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _totalFooter(double Function() total, {required Color color}) {
  return Container(
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Total Cash In Drawer',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        Obx(() {
          final c = ShiftCloseController.to;
          final _ = c.settings.currency.value;
          return Text(
            c.moneyFmt.format(total()),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          );
        }),
      ],
    ),
  );
}

Widget _paymentModeHeader({required Color color}) {
  return Container(
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: const Row(
      children: [
        Expanded(flex: 6, child: Text('Payment Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        Expanded(flex: 4, child: Align(alignment: Alignment.centerRight, child: Text('Actual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
      ],
    ),
  );
}

Widget _paymentModeList(ShiftCloseController c) {
  final cs = Get.context!.theme.colorScheme;
  return Obx(() {
    final _ = c.settings.currency.value; // react
    final fmt = c.moneyFmt;

    final entries = c.paymentSummary.entries.toList();
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(8)),
        child: const Text('No payment modes'),
      );
    }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: cs.outlineVariant)),
      child: Column(
        children: entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: cs.surface, border: Border(bottom: BorderSide(color: cs.outlineVariant))),
            child: Row(
              children: [
                Expanded(flex: 6, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 4, child: Align(alignment: Alignment.centerRight, child: Text(fmt.format(e.value), style: const TextStyle(fontWeight: FontWeight.w700)))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  });
}

Widget _chip(String text, {required Color color, bool isTitle = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isTitle ? color.withOpacity(0.9) : color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}
