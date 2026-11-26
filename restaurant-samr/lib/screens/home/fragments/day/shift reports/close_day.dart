import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/captain/login/auth_service.dart';
import 'package:splash_screen_03/model/enity_day_report.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/enum_bill_status.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/repository/day_repo.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/utils/app_routes.dart';

class Denomination {
  Denomination(this.label, this.value, {int count = 0}) : count = count.obs;
  final String label;
  final double value;
  final RxInt count;
  double get amount => value * count.value;
}

// ============================================================================
//                          CLOSE SHIFT CONTROLLER
// ============================================================================
class CloseShiftController extends GetxController {
  static CloseShiftController get to => Get.find<CloseShiftController>();

  final DayReportRepo repo = Get.find<DayReportRepo>();
  final settings = Get.find<ControllerSetting>();

  final now = DateTime.now().obs;
  late final Timer _clock;

  /// Holds the currently open day report (gets updated after close)
  final openReport = Rxn<EntityDayReport>();

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
  Future<bool> closeShift() async {
    // ------------------------------------------------------------
    // 1) Check for un-settled/open bills — DO NOT ALLOW CLOSE
    // ------------------------------------------------------------
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
        "Cannot Close Day",
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

    // ------------------------------------------------------------
    // 2) Calculate final closing cash
    // ------------------------------------------------------------
    final closingCash = totalInDrawer;

    // ------------------------------------------------------------
    // 3) Store closing day summary into DB
    // ------------------------------------------------------------
    final closedReport = repo.closeOpenDay(
      closingComments: comments.value,
      closingCash: closingCash,
      totalSales: paymentSummary.values.fold(0.0, (s, v) => s! + v),
      totalRefunds: 0,
      totalExpenses: totalExpenses.value,
    );

    if (closedReport == null) {
      Get.snackbar(
        "Error",
        "No open day found to close.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade200,
      );
      return false;
    }

    // ------------------------------------------------------------
    // 4) Update the reactive openReport
    // ------------------------------------------------------------
    openReport.value = closedReport;

    // ------------------------------------------------------------
    // 5) Success notification
    // ------------------------------------------------------------
    Get.snackbar(
      "Shift Closed Successfully",
      "Opening: ${moneyFmt.format(closedReport.openingCash)}\n"
          "Closing: ${moneyFmt.format(closingCash)}",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );

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

    // get active day report
    final open = repo.currentOpen();
    openReport.value = open;

    if (open != null) {
      username.value = open.username;
      openingBalance.value = open.openingCash;
    }

    // denomination text controllers
    for (final d in denoms) {
      final tc = TextEditingController(text: d.count.value.toString());
      textControllers[d] = tc;
      ever<int>(d.count, (_) => _syncText(d));
    }

    // Default payment modes
    if (paymentSummary.isEmpty) {
      _calculateShiftTotals();
    }
  }

  void _calculateShiftTotals() {
    final open = repo.currentOpen();
    if (open == null) {
      paymentSummary.assignAll({'Cash': 0, 'Card': 0, 'UPI': 0});
      return;
    }

    final start = open.openedAt;
    final end = DateTime.now();
    final Box<EntityOrder> box = Get.find<Box<EntityOrder>>();

    // Fetch all bills that interact with this shift
    // We consider a bill part of this shift if it was SETTLED or CANCELLED during the shift
    final bills = box.getAll().where((b) {
      final status = (b.status ?? '').toLowerCase();
      if (status != 'settled' && status != 'cancelled') return false;

      // Resolve the relevant time
      DateTime? time;
      try {
        final dyn = b as dynamic;
        time =
            _parseDate(dyn.settledOn) ??
            _parseDate(dyn.closedOn) ??
            _parseDate(dyn.endTime) ??
            _parseDate(b.createdOn);
      } catch (_) {}
      time ??= DateTime.now();

      return time.isAfter(start) && time.isBefore(end);
    }).toList();

    // double totalExp = 0.0; // If you have expenses logic, add here
    int fulfilled = 0;
    int cancelled = 0;
    int complimentary = 0;
    final Map<String, double> modeTotals = {};

    for (final b in bills) {
      final status = (b.status ?? '').toLowerCase();
      if (status == 'cancelled') {
        cancelled++;
        continue;
      }

      if (status == 'settled') {
        fulfilled++;
        // Check complimentary
        // if (b.isComplimentary) complimentary++;

        // Aggregate payments
        final splits = _extractPaymentSplits(b);
        splits.forEach((mode, amount) {
          modeTotals[mode] = (modeTotals[mode] ?? 0.0) + amount;
        });
      }
    }

    // Update observables
    fulfilledOrders.value = fulfilled;
    cancelledOrders.value = cancelled;
    complimentaryOrders.value = complimentary;
    // totalExpenses.value = totalExp; // Update if expenses are tracked

    if (modeTotals.isEmpty) {
      paymentSummary.assignAll({'Cash': 0, 'Card': 0, 'UPI': 0});
    } else {
      paymentSummary.assignAll(modeTotals);
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  Map<String, double> _extractPaymentSplits(EntityOrder b) {
    // Simplified version of ControllerDashboard logic
    final Map<String, double> splits = {};
    try {
      for (final p in b.payments) {
        if (p.price > 0) {
          final mode = p.mode;
          splits[mode] = (splits[mode] ?? 0.0) + p.price;
        }
      }
      // Fallback if no payments but total > 0 (assume Cash or single mode)
      if (splits.isEmpty && (b.totalAmount ?? 0) > 0) {
        // Try to find mode in other fields
        String mode = 'Cash';
        try {
          final dyn = b as dynamic;
          mode = dyn.paymentMode ?? dyn.mode ?? 'Cash';
        } catch (_) {}
        splits[mode] = b.totalAmount!;
      }
    } catch (_) {}
    return splits;
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

class CloseShiftDialog extends StatelessWidget {
  const CloseShiftDialog({super.key});

  static Future<void> show({
    Map<String, double>? paymentModeTotals,
    int? fulfilled,
    int? cancelled,
    int? complimentary,
    double? expenses,
  }) async {
    if (!Get.isRegistered<DayReportRepo>()) {
      Get.put(DayReportRepo(), permanent: true);
    }
    final ctrl = Get.put(CloseShiftController());
    ctrl.setMetrics(
      paymentModeTotals: paymentModeTotals,
      fulfilled: fulfilled,
      cancelled: cancelled,
      complimentary: complimentary,
      expenses: expenses,
    );
    await Get.dialog(const CloseShiftDialog(), barrierDismissible: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = CloseShiftController.to;
    final fmt = NumberFormat.currency(locale: 'en_AE', symbol: 'AED ');

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
                        'Closing Day & Shift - ${df.format(c.now.value)}',
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
                                // Middle stats (removed Revenue ID & Cash Drawer ID)
                                Expanded(
                                  flex: 5,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Obx(
                                          () => _chip(
                                            'Username: ${c.username.value}',
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _chip(
                                          'Order Statistics (Shift)',
                                          color: Colors.teal,
                                          isTitle: true,
                                        ),
                                        const SizedBox(height: 8),
                                        Obx(
                                          () => _chip(
                                            'Fulfilled Orders: ${c.fulfilledOrders.value}',
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Obx(
                                          () => _chip(
                                            'Cancelled Orders: ${c.cancelledOrders.value}',
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Obx(
                                          () => _chip(
                                            'Complementary Orders: ${c.complimentaryOrders.value}',
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Right stats + comments + buttons
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _chip(
                                        'Closing Day Summary',
                                        color: Colors.teal,
                                        isTitle: true,
                                      ),
                                      const SizedBox(height: 8),
                                      _chip(
                                        'Account Statistics',
                                        color: Colors.teal,
                                        isTitle: true,
                                      ),
                                      const SizedBox(height: 8),
                                      // Opening Balance
                                      Obx(() {
                                        // touch the currency to make this reactive to settings.currency changes
                                        final _ = c.settings.currency.value;
                                        return _chip(
                                          'Opening Balance: ${c.moneyFmt.format(c.openingBalance.value)}',
                                          color: Colors.teal,
                                        );
                                      }),

                                      // Expenses
                                      Obx(() {
                                        final _ = c.settings.currency.value;
                                        return _chip(
                                          'Expenses: ${c.moneyFmt.format(c.totalExpenses.value)}',
                                          color: Colors.teal,
                                        );
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
                                                backgroundColor:
                                                    Colors.red.shade600,
                                              ),
                                              onPressed: () => Get.back(),
                                              child: const Text('Close'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                              ),
                                              onPressed: () async {
                                                final bool wasShiftClosed =
                                                    await c.closeShift();

                                                if (wasShiftClosed) {
                                                  Get.back(); // close dialog

                                                  final storage = GetStorage();
                                                  await storage.write(
                                                    'showShiftDialogNextLogin',
                                                    true,
                                                  );

                                                  // 🔥 Unified Logout
                                                  final auth =
                                                      Get.find<AuthService>();
                                                  await auth.logout();
                                                }
                                              },
                                              child: const Text(
                                                'CLOSE DAY AND SHIFT',
                                                style: TextStyle(
                                                  fontSize: 11,
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

/* ---------- UI bits (Unchanged) ---------- */

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

Widget _denominationList(CloseShiftController c) {
  final cs = Get.context!.theme.colorScheme;
  return ListView.separated(
    itemCount: c.denoms.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (ctx, i) {
      final d = c.denoms[i];
      final tc = c.textControllers[d]!;
      return Container(
        decoration: BoxDecoration(
          color: i.isEven
              ? cs.surface
              : cs.surfaceContainerHighest.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Denomination label (reacts to currency changes)
            Expanded(
              flex: 5,
              child: Obx(() {
                final _ = c.settings.currency.value;
                return Text(
                  "",
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
                    onPressed: () => c.decrement(d),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Flexible(
                    child: Obx(() {
                      final desired = d.count.value.toString();
                      if (tc.text != desired) {
                        tc.text = desired;
                        tc.selection = TextSelection.collapsed(
                          offset: tc.text.length,
                        );
                      }
                      return TextFormField(
                        controller: tc,
                        textAlign: TextAlign.center,
                        onChanged: (v) => c.setCount(d, v),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: '0',
                          isDense: true,
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    onPressed: () => c.increment(d),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),

            // Amount (reacts to currency changes)
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
          final c = CloseShiftController.to;
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
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: const Row(
      children: [
        Expanded(
          flex: 6,
          child: Text(
            'Payment Mode',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Actual',
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

Widget _paymentModeList(CloseShiftController c) {
  final cs = Get.context!.theme.colorScheme;
  return Obx(() {
    final _ = c.settings.currency.value; // react to currency
    final fmt = c.moneyFmt;

    final entries = c.paymentSummary.entries.toList();
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No payment modes'),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text(
                    e.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      fmt.format(e.value),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
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
