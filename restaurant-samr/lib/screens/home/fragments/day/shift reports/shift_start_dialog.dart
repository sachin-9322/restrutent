// -----------------------------------------------------------------------------
// SHIFT START DIALOG (Exact Same UI as Day Start Dialog, Only Logic Updated)
// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:splash_screen_03/model/enity_day_report.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/repository/day_repo.dart';
import 'package:splash_screen_03/repository/shift_report_repo.dart';
import 'package:splash_screen_03/screens/home/fragments/day/day_report.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';

// ============================================================================
// SHIFT START CONTROLLER
// ============================================================================
class StartShiftController extends GetxController {
  final DayReportRepo dayRepo = Get.find<DayReportRepo>();
  final ShiftReportRepo shiftRepo = Get.find<ShiftReportRepo>();
  final settings = Get.find<ControllerSetting>();

  final now = DateTime.now().obs;
  late final Timer _clock;

  final username = ''.obs;
  final comments = ''.obs;
  final previousDayHistory = <String>[].obs;

  final Map<Denomination, TextEditingController> textControllers = {};

  NumberFormat get moneyFmt =>
      NumberFormat.currency(locale: settings.currLocale, symbol: '${settings.currSymbol} ');

  // Denominations
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

  double get totalInDrawer =>
      denoms.fold(0.0, (sum, d) => sum + d.amount);

  String denomLabel(Denomination d) {
    if (d.value >= 1) {
      return '${settings.currSymbol} ${d.value.toStringAsFixed(0)}';
    } else {
      final sub = settings.subunitLabel;
      final subValue = (d.value * 100).round();
      return '$sub $subValue';
    }
  }

  @override
  void onInit() {
    super.onInit();

    final storage = StorageRepository();
    username.value = storage.username;

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });

    previousDayHistory.assignAll(dayRepo.previousDayHistoryLines());

    for (final d in denoms) {
      final tc = TextEditingController(text: d.count.value.toString());
      textControllers[d] = tc;
      ever(d.count, (_) => _syncText(d));
    }
  }

  @override
  void onClose() {
    _clock.cancel();
    for (final t in textControllers.values) {
      t.dispose();
    }
    textControllers.clear();
    super.onClose();
  }

  // sync text
  void _syncText(Denomination d) {
    final tc = textControllers[d];
    if (tc == null) return;
    if (tc.text != d.count.value.toString()) {
      tc.text = d.count.value.toString();
      tc.selection = TextSelection.collapsed(offset: tc.text.length);
    }
  }

  void setCount(Denomination d, String v) {
    final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    d.count.value = parsed;
  }

  void increment(Denomination d) {
    d.count.value++;
  }

  void decrement(Denomination d) {
    d.count.value = (d.count.value - 1).clamp(0, 999999);
  }

  // ========================================================================
  // START SHIFT
  // ========================================================================
  Future<void> startShift() async {
    final openDay = dayRepo.currentOpen();
    if (openDay == null) {
      Get.snackbar("Error", "No open day found!", backgroundColor: Colors.red);
      return;
    }

    final openingCash = totalInDrawer;

    shiftRepo.startShift(
      dayId: openDay.id,
      username: username.value,
      openingCash: openingCash,
      comments: comments.value,
    );

    Get.back();
    Get.snackbar(
      'Shift Started',
      'Opening Cash: ${moneyFmt.format(openingCash)}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}

// ============================================================================
// SHIFT START DIALOG UI
// ============================================================================
class ShifttStartDialog extends StatelessWidget {
  const ShifttStartDialog({super.key});

  static Future<void> show() async {
    if (!Get.isRegistered<StartShiftController>()) {
      Get.put(StartShiftController());
    }
    await Get.dialog(const ShifttStartDialog(), barrierDismissible: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StartShiftController>();
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
                        'Start Shift | User: ${c.username.value} | ${df.format(c.now.value)}',
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _denominationHeader(context),
                    const SizedBox(height: 8),
                    Expanded(child: _denominationList(context, c)),
                    const SizedBox(height: 8),
                    _totalFooter(context, c),
                    const SizedBox(height: 16),

                    // HISTORY
                    Card(
                      elevation: 1,
                      child: ExpansionTile(
                        title: const Text('Previous Day History'),
                        initiallyExpanded: false,
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Obx(() {
                            final items = c.previousDayHistory;
                            if (items.isEmpty) {
                              return const Text("No history found");
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items
                                  .map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.history, size: 16, color: tealColor),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            );
                          })
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

                    // BUTTON
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: c.startShift,
                        style: FilledButton.styleFrom(
                          backgroundColor: tealColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Start Shift"),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SUPPORTING WIDGETS (REQUIRED!)
// ============================================================================

Widget _denominationHeader(BuildContext context) {
  return Container(
    decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: const Row(
      children: [
        Expanded(flex: 5, child: Text("Currency Denomination", style: TextStyle(color: Colors.white))),
        Expanded(flex: 3, child: Text("Count", style: TextStyle(color: Colors.white))),
        Expanded(flex: 3, child: Text("Amount", textAlign: TextAlign.right, style: TextStyle(color: Colors.white))),
      ],
    ),
  );
}

Widget _denominationList(BuildContext context, StartShiftController c) {
  return ListView.separated(
    itemCount: c.denoms.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, i) {
      final d = c.denoms[i];
      final tc = c.textControllers[d]!;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Obx(() => Text(
                    c.denomLabel(d),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => c.decrement(d)),
                  Expanded(
                    child: Obx(() {
                      if (tc.text != d.count.value.toString()) {
                        tc.text = d.count.value.toString();
                        tc.selection = TextSelection.collapsed(offset: tc.text.length);
                      }
                      return TextFormField(
                        controller: tc,
                        textAlign: TextAlign.center,
                        onChanged: (v) => c.setCount(d, v),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(isDense: true),
                      );
                    }),
                  ),
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => c.increment(d)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Obx(() => Text(
                    c.moneyFmt.format(d.amount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )),
            ),
          ],
        ),
      );
    },
  );
}

Widget _totalFooter(BuildContext context, StartShiftController c) {
  final RxDouble manual = 0.0.obs;
  final RxBool isManual = false.obs;

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(8)),
    child: Row(
      children: [
        const Expanded(
          child: Text("Total Cash In Drawer", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          width: 160,
          child: Obx(() {
            final value = isManual.value ? manual.value : c.totalInDrawer;
            final controller = TextEditingController(text: c.moneyFmt.format(value));
            controller.selection = TextSelection.collapsed(offset: controller.text.length);

            return TextFormField(
              controller: controller,
              textAlign: TextAlign.right,
              onChanged: (v) {
                manual.value = double.tryParse(v.replaceAll(RegExp(r"[^0-9.]"), "")) ?? 0.0;
                isManual.value = true;
              },
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.teal),
                  onPressed: () {
                    isManual.value = false;
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }),
        ),
      ],
    ),
  );
}
