import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/EntityShiftReport.dart';
import 'package:splash_screen_03/model/enity_day_report.dart';


import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/repository/day_repo.dart';
import 'package:splash_screen_03/repository/shift_report_repo.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';

class DayStatusController extends GetxController {
  final DayReportRepo repo = Get.find<DayReportRepo>();
  final openReport = Rxn<EntityDayReport>();

  Future<void> refreshOpen() async {
    openReport.value = repo.currentOpen();
  }

  @override
  void onInit() {
    super.onInit();
    refreshOpen();
  }
  /// returns true if an open day exists, false otherwise
  Future<bool> hasOpenDay() async {
    try {
      final open = repo.currentOpen();
      return open != null;
    } catch (e) {
      // safe fallback
      return false;
    }
  }

}

class Denomination {
  Denomination(this.label, this.value, {int count = 0}) : count = count.obs;
  final String label;
  final double value;
  final RxInt count;
  double get amount => value * count.value;
}

var rxDayReportList = <EntityDayReport>[].obs; // like rxMasterCategoryList



class ShiftController extends GetxController {
  static ShiftController get to => Get.find<ShiftController>();
final currentShift = Rxn<EntityShiftReport>();
Future<void> refreshAll() async {
  final openDay = repo.currentOpen();
  if (openDay != null) {
    final shiftRepo = Get.find<ShiftReportRepo>();
    currentShift.value = shiftRepo.currentOpenShift(openDay.id);
  }
}

  final now = DateTime.now().obs;
  late final Timer _clock;

  final username = ''.obs;
  final previousDayHistory = <String>[].obs;
  final Map<Denomination, TextEditingController> textControllers = {};

  final settings = Get.find<ControllerSetting>();
  final comments = ''.obs;

  NumberFormat get moneyFmt =>
      NumberFormat.currency(locale: settings.currLocale, symbol: '${settings.currSymbol} ');

  String denomLabel(Denomination d) {
    if (d.value >= 1) {
      return '${settings.currSymbol} ${d.value.toStringAsFixed(0)}';
    } else {
      final sub = settings.subunitLabel;
      final subValue = (d.value * 100).round();
      return '$sub $subValue';
    }
  }

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

  double get totalInDrawer => denoms.fold(0.0, (sum, d) => sum + d.amount);

  final DayReportRepo repo = Get.find<DayReportRepo>();
  final currentDayReportId = RxnInt();

  void setCount(Denomination d, String v) {
    final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
    d.count.value = parsed.clamp(0, 999999);
  }

  void _syncText(Denomination d) {
    final tc = textControllers[d];
    if (tc == null) return;
    final desired = d.count.value.toString();
    if (tc.text != desired) {
      tc.text = desired;
      tc.selection = TextSelection.collapsed(offset: tc.text.length);
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

  Future<void> startShift() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final snapshot = denoms
        .map((d) => EntityDenominationCount(
              label: denomLabel(d),
              unitValue: d.value,
              count: d.count.value,
            ))
        .toList();

    // compute invoice numbers
    final nextStart = repo.nextInvoiceStart();
    final nextEnd = nextStart; // initially same; you may extend logic later

    final report = await repo.startDay(
      username: username.value,
      comments: comments.value,
      denomSnapshot: snapshot,
      currencyCode: settings.currCode,
      currencySymbol: settings.currSymbol,
      currencyLocale: settings.currLocale,
      invoiceStart: nextStart,
      invoiceEnd: nextEnd,
    );

    currentDayReportId.value = report.id;
    rxDayReportList.insert(0, report);

    previousDayHistory.assignAll(repo.previousDayHistoryLines());

    Get.back();
    Get.snackbar(
      'Shift Started',
      'Username: ${username.value} | Total: ${moneyFmt.format(totalInDrawer)}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onInit() {
    super.onInit();
    final storage = StorageRepository();
    username.value = storage.username;

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });

    previousDayHistory.assignAll(repo.previousDayHistoryLines());

    for (final d in denoms) {
      final tc = TextEditingController(text: d.count.value.toString());
      textControllers[d] = tc;
      ever<int>(d.count, (_) => _syncText(d));
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

class ShiftStartDialog extends StatelessWidget {
  const ShiftStartDialog({super.key});

  static Future<void> show() async {
    if (!Get.isRegistered<ShiftController>()) {
      Get.put(ShiftController());
    }
    await Get.dialog(const ShiftStartDialog(), barrierDismissible: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = ShiftController.to;
    const tealColor = Colors.teal;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: tealColor,
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() {
                      final df = DateFormat('dd/MM/yyyy hh:mm:ss a');
                      return Text(
                        'User: ${c.username.value} | ${df.format(c.now.value)}',
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

            // MAIN BODY
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _denominationHeader(context),
                    const SizedBox(height: 8),
                    Expanded(child: _denominationList(context, c)),
                    const SizedBox(height: 8),
                    _totalFooter(context, c),

                    const SizedBox(height: 8),

                    // Previous Day History (Collapsible) — FIX: add text lines
                    Card(
                      elevation: 1,
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        title: const Text(
                          'Previous Day History',
                          style: TextStyle(
                            color: tealColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [
                          Obx(() {
                            final items = c.previousDayHistory;
                            if (items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('No history found.'),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.history,
                                            size: 16,
                                            color: tealColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(e)),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      minLines: 3,
                      maxLines: 4,
                      onChanged: (v) => c.comments.value = v,
                      decoration: const InputDecoration(
                        hintText: 'Comments here...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: tealColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        onPressed: c.startShift,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Start Day and Shift'),
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

/* ===================== SUPPORTING UI ===================== */

Widget _denominationHeader(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.teal,
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

Widget _denominationList(BuildContext context, ShiftController c) {
  final cs = Theme.of(context).colorScheme;
  return ListView.separated(
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
            // Label reacts to settings.currency
            Expanded(
              flex: 5,
              child: Obx(() {
                final _ = c.settings.currency.value; // trigger rebuild
                return Text(
                  c.denomLabel(d),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                );
              }),
            ),
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
                        tc.selection = TextSelection.collapsed(
                          offset: tc.text.length,
                        );
                      }
                      return TextFormField(
                        textAlign: TextAlign.center,
                        controller: tc,
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
                    tooltip: 'Increase',
                    onPressed: () => c.increment(d),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(() {
                  final _ = c
                      .settings
                      .currency
                      .value; // trigger rebuild on currency change
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
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemCount: c.denoms.length,
  );
}

Widget _totalFooter(BuildContext context, ShiftController c) {
  final RxDouble manualTotal = 0.0.obs;
  final RxBool isManual = false.obs;

  return Container(
    decoration: BoxDecoration(
      color: Colors.teal.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Total Cash In Drawer',
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(
          width: 180,
          child: Obx(() {
            final _ = c.settings.currency.value; // reactive to currency change
            final displayValue = isManual.value
                ? manualTotal.value
                : c.totalInDrawer;
            final controller = TextEditingController(
              text: c.moneyFmt.format(displayValue),
            );
            controller.selection = TextSelection.collapsed(
              offset: controller.text.length,
            );

            return TextFormField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
                suffixIcon: IconButton(
                  tooltip: 'Reset to auto',
                  icon: const Icon(Icons.refresh, color: Colors.teal),
                  onPressed: () {
                    isManual.value = false;
                    manualTotal.value = 0.0;
                  },
                ),
              ),
              onChanged: (v) {
                final parsed =
                    double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0.0;
                manualTotal.value = parsed;
                isManual.value = true;
              },
            );
          }),
        ),
      ],
    ),
  );
}
