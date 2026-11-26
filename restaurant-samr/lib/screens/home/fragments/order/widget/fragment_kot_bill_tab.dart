import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart';
import 'package:splash_screen_03/model/entity_printer.dart';
import 'package:splash_screen_03/model/entity_table.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/printer/printer_configuration.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/screens/home/fragments/order/fragemnt_split.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/order/widget/activity_bill_preview.dart';
import 'package:splash_screen_03/screens/home/fragments/order/widget/payment_dialog.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/raw_pritner_service.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/wifi_pritner.dart';
import 'package:splash_screen_03/screens/home/fragments/sub_order_type/controller_sub_order.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/users/controller_user.dart';
import 'package:splash_screen_03/utils/sanbar.dart';

import '../../../../../model/entity_kot.dart';

class OrderTableContentBill extends StatelessWidget {
  final ThemeData theme;
  const OrderTableContentBill({required this.theme, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ControllerOrder>();
    final ControllerTable tableController = Get.find<ControllerTable>();
    final ControllerSetting settingController = Get.find<ControllerSetting>();
    final tableName = tableController.selectedTable.value?.tableName ?? '';

    final customerName = controller.rxCustomerName.value.trim();
    final customerMobile = controller.rxCustomerMobile.value.trim();
    final customerAddress = controller.rxCustomerAddress.value.trim();

    // --- Money format ---
    String formatMoney(ControllerSetting s, double amount) {
      return NumberFormat.currency(
        locale: s.currLocale,
        symbol: s.currSymbol,
        decimalDigits: 2,
      ).format(amount);
    }

    final ControllerOrder catController = Get.isRegistered<ControllerOrder>()
        ? Get.find<ControllerOrder>()
        : Get.put(ControllerOrder());

    final paymentMode = "Cash".obs;

    final ControllerSubOrder subController =
        Get.isRegistered<ControllerSubOrder>()
        ? Get.find<ControllerSubOrder>()
        : Get.put(ControllerSubOrder());
    const double kSnackWidth = 320;
    const double kSnackBottomGap = 18;

    final selectedName =
        tableController.selectedTable.value?.tableName?.trim() ?? '';
    if (selectedName.isNotEmpty) {
      // Safe, called after build; won’t loop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.ensureLoadedForTable(selectedName, latestOnly: false);
      });
    }

    Future<void> ensureOrderSaved() async {
      final selected = tableController.selectedTable.value;

      // Resolve current table name robustly
      String tableName = (selected?.tableName ?? '').trim();
      if (tableName.isEmpty) {
        tableName = catController.rxCurrentTable.value.trim();
      }

      // For Dine-In, require a table selected
      if (catController.rxOrderType.value == "Dine-In" && tableName.isEmpty) {
        Get.snackbar(
          "Select table",
          "Please select a table first.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // For non Dine-In, fallback to order type (Quick Bill / Delivery / PickUp)
      if (tableName.isEmpty) {
        tableName = catController.rxOrderType.value;
      }

      // Work on the correct table bucket
      catController.loadTableOrders(tableName);

      // Only save if there are unsent items for this table
      final data = catController.tableOrders[tableName];
      final hasLocal =
          (data?.orderItems.isNotEmpty ?? false) ||
          (data?.extraItems.isNotEmpty ?? false);
      if (!hasLocal) return;

      await catController.saveOrder(tableName, selected?.seats ?? 0, "booked");

      // Optional: refresh total immediately (stable calc)
      catController.getTotalPrice(forTable: tableName);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final total = controller.getTotalPrice();
      final bill = controller.getActiveBillForTableName(tableName);

      // ORIGINAL TOTAL (items only)
      final originalTotal = controller.getTotalPrice(forTable: tableName);

      // DISCOUNT APPLIED
      final discount = bill?.discountAmount ?? 0;

      // FINAL TOTAL (use saved bill total OR compute fallback)
      final finalTotal = bill?.totalAmount != null
          ? bill!.totalAmount!
          : (originalTotal - discount);

      return Container(
        color: isDark ? const Color(0xFF222426) : Colors.grey.shade200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            //   decoration: BoxDecoration(
            //     color: isDark ? const Color(0xFF1B1C1E) : Colors.grey.shade300,
            //     borderRadius: BorderRadius.circular(6),
            //   ),
            //   child: Row(
            //     children: [
            //       Text(
            //         "Bill ${controller.getActiveBillForTableName(tableName)?.orderNumber ?? ''}",
            //         style: TextStyle(
            //           color: isDark ? Colors.white : Colors.black87,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       const SizedBox(width: 10),
            //       Text(
            //         "Table $tableName",
            //         style: TextStyle(
            //           color: isDark ? Colors.white70 : Colors.black54,
            //         ),
            //       ),
            //       const Spacer(),
            //       _pillButton(
            //         "Split",
            //         isDark ? Colors.white : Colors.black87,
            //         () {
            //         
            //         },
            //       ),
            //     ],
            //   ),
            // ),

            const SizedBox(height: 10),

            // -------- Table header --------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? const Color(0xFF222426) : Colors.grey.shade200,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      "Item",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Qty",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Price",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------- Items list --------
            Expanded(
              child: Container(
                color: isDark ? Colors.black87 : Colors.white,
                child: Obx(() {
                  final items = controller.rxKotItems;

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        "No items",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF222426) // Dark mode background
                              : Colors.grey.shade200, // Light mode background
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "${item.qty}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.price.toStringAsFixed(2),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.grey.withOpacity(0.3),
                            indent: 10,
                            endIndent: 10,
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ),

            // -------- Total + Payment Options + Bottom Actions --------
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1C1E) : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- Total ----------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B1C1E)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Total",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // -------------------------------------------------------------
                                // ORIGINAL TOTAL WITH STRIKE-THROUGH (only when discount applied)
                                // -------------------------------------------------------------
                                if (discount > 0)
                                  Text(
                                    formatMoney(
                                      settingController,
                                      originalTotal,
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.redAccent,
                                      decorationThickness: 2,
                                    ),
                                  ),

                                if (discount > 0) const SizedBox(width: 6),

                                // -------------------------------------------------------------
                                // FINAL TOTAL (always read from bill.totalAmount)
                                // -------------------------------------------------------------
                                Text(
                                  formatMoney(settingController, finalTotal),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ---------- Icon Row ----------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: isDark
                        ? const Color(0xFF1B1C1E)
                        : Colors.grey.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _paymentIcon(Icons.attach_money, "Cash"),
                        _paymentIcon(Icons.credit_card, "Card"),
                        _paymentIcon(Icons.person, "Customer"),
                        _paymentIcon(Icons.card_giftcard, "Discount"),
                        _paymentIcon(Icons.stars, "Reward"),
                        _paymentIcon(Icons.room_service, "Service"),
                      ],
                    ),
                  ),

                  // ---------- Payment Radio Options ----------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: isDark
                        ? const Color(0xFF1B1C1E)
                        : Colors.grey.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _paymentRadio(
                          "Bharat Pay",
                          paymentMode,
                          "Bharat Pay",
                          isDark: isDark,
                        ),
                        _paymentRadio(
                          "Zomato Pro",
                          paymentMode,
                          "Zomato Pro",
                          isDark: isDark,
                        ),
                        _paymentRadio(
                          "Jio Money",
                          paymentMode,
                          "Jio Money",
                          isDark: isDark,
                        ),
                        _paymentRadio(
                          "Others",
                          paymentMode,
                          "Others",
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFF1F2021),
                  ),

                  // ---------- Bottom Buttons ----------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: isDark
                        ? const Color(0xFF1B1C1E)
                        : Colors.grey.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _bottomTealButton(
                            isDark: isDark,
                            "Save bill",
                            Icons.print_outlined,
                            onTap: () async {
                              debugPrint(
                                '🟡 [PrintBill] ====== Starting Bill Print Process ======',
                              );

                              final isQuickBill =
                                  controller.rxOrderType.value
                                      .trim()
                                      .toLowerCase() ==
                                  'quick bill';

                              // 🔹 Resolve table name safely
                              final selected =
                                  tableController.selectedTable.value;
                              String tableName = (selected?.tableName ?? '')
                                  .trim();
                              if (tableName.isEmpty)
                                tableName = catController.rxCurrentTable.value
                                    .trim();
                              if (tableName.isEmpty)
                                tableName = catController.rxOrderType.value
                                    .trim();

                              debugPrint(
                                '🟡 [PrintBill] Using TableName: $tableName',
                              );

                              final hasLocalCart = controller
                                  .hasUnsentItemsForTable(tableName);
                              final hasServerKot = controller
                                  .hasBookedKotForTable(tableName);

                              // 🔹 Prevent printing if KOT not sent for dine-in
                              if (hasLocalCart && !isQuickBill) {
                                showMiniSnack(
                                  context,
                                  "KOT required",
                                  "You have pending items not sent to kitchen. Please print KOT first.",
                                  type: MiniSnackType.warning,
                                  maxWidth: kSnackWidth,
                                  bottomGap: kSnackBottomGap,
                                );
                                return;
                              }

                              // 🔹 Save quick bill items if any
                              if (hasLocalCart && isQuickBill) {
                                await ensureOrderSaved();
                              }

                              // 🔹 Ensure bill exists before printing
                              await ensureOrderSaved();
                              final EntityOrder? activeBill = controller
                                  .getActiveBillForTableName(tableName);
                              if (activeBill == null) {
                                showMiniSnack(
                                  context,
                                  "Warning",
                                  "Could not find the bill to print.",
                                  type: MiniSnackType.warning,
                                  maxWidth: kSnackWidth,
                                  bottomGap: kSnackBottomGap,
                                );
                                return;
                              }

                              // 🔹 Fetch KOTs and items
                              final List<KotGroup> kotsForBill = controller
                                  .getKotsForActiveBillOfTable(tableName);
                              final allItemsForBill = controller
                                  .getBillGroupedItemsForTable(tableName);

                              // 🔹 Save customer details on bill
                              activeBill.customerName =
                                  controller.rxCustomerName.value.isNotEmpty
                                  ? controller.rxCustomerName.value
                                  : null;
                              activeBill.customerMobile =
                                  controller.rxCustomerMobile.value.isNotEmpty
                                  ? controller.rxCustomerMobile.value
                                  : null;
                              activeBill.customerAddress =
                                  controller.rxCustomerAddress.value.isNotEmpty
                                  ? controller.rxCustomerAddress.value
                                  : null;

                              controller.boxEntityOrder.put(activeBill);

                              // =======================================================
                              // 🔹 FIND BILL PRINTER CONFIGURATION
                              // =======================================================
                              final box = Get.find<Box<EntityPrinter>>();
                              EntityPrinter? printer = box
                                  .query(
                                    EntityPrinter_.configType.equals('BILL'),
                                  )
                                  .build()
                                  .findFirst();

                              printer ??= box
                                  .query(
                                    EntityPrinter_.configType.equals('KOT'),
                                  )
                                  .build()
                                  .findFirst();

                              if (printer == null) {
                                controller.markBillPrepared(tableName);
                                showMiniSnack(
                                  context,
                                  "Saved Only",
                                  "No printer configured. Bill saved successfully.",
                                  type: MiniSnackType.info,
                                  maxWidth: kSnackWidth,
                                  bottomGap: kSnackBottomGap,
                                );
                                debugPrint(
                                  '⚠️ [PrintBill] No printer configured. Saved only.',
                                );
                                return;
                              }

                              final url = (printer.printUrl ?? '')
                                  .toLowerCase();
                              final copies = (printer.noOfCop ?? 1).clamp(
                                1,
                                10,
                              );
                              final isBluetooth =
                                  url.startsWith('bluetooth://') ||
                                  url.contains('bluetooth');
                              final cfg = (printer.configType ?? 'BILL')
                                  .toUpperCase();

                              debugPrint(
                                '🟡 [PrintBill] Printer config: type=$cfg, url=$url, copies=$copies, BT=$isBluetooth',
                              );

                              // =======================================================
                              // 🔹 BLUETOOTH PRINTER — ASYNC OPTIMIZED (instant save)
                              // =======================================================
                              if (isBluetooth) {
                                if (!Get.isRegistered<RawBtPrinterService>()) {
                                  Get.put(
                                    RawBtPrinterService(),
                                    permanent: true,
                                  );
                                }
                                final bt = Get.find<RawBtPrinterService>();

                                // ✅ 1. Save instantly and show immediate feedback
                                controller.markBillPrepared(tableName);
                                if (context.mounted) {
                                  showMiniSnack(
                                    context,
                                    "Saving...",
                                    "Bill saved.",
                                    type: MiniSnackType.info,
                                    maxWidth: kSnackWidth,
                                    bottomGap: kSnackBottomGap,
                                  );
                                }

                                // ✅ 2. Start async printing (non-blocking)
                                Future(() async {
                                  try {
                                    final connected = await bt.ensureConnected(
                                      timeoutMs: 2000,
                                    );
                                    if (!connected) {
                                      debugPrint(
                                        '⚠️ [PrintBill] Printer not connected, saved only.',
                                      );
                                      return;
                                    }

                                    for (int i = 0; i < copies; i++) {
                                      await bt.printBillEscPosByConfigType(
                                        configType: cfg,
                                        bill: activeBill,
                                        groupedItems: allItemsForBill,
                                        kots: kotsForBill,
                                      );
                                    }

                                    debugPrint(
                                      '✅ [PrintBill] Background print complete.',
                                    );
                                    if (context.mounted) {
                                      showMiniSnack(
                                        context,
                                        "Printed",
                                        "Bill printed successfully.",
                                        type: MiniSnackType.success,
                                        maxWidth: kSnackWidth,
                                        bottomGap: kSnackBottomGap,
                                      );
                                    }
                                  } catch (e, st) {
                                    debugPrint(
                                      '❌ [PrintBill] Background print failed: $e\n$st',
                                    );
                                    if (context.mounted) {
                                      showMiniSnack(
                                        context,
                                        "Printer Error",
                                        "Saved only (printing failed).",
                                        type: MiniSnackType.warning,
                                        maxWidth: kSnackWidth,
                                        bottomGap: kSnackBottomGap,
                                      );
                                    }
                                  }
                                });

                                // ✅ 3. Return immediately — do not wait
                                return;
                              }

                              // =======================================================
                              // 🔹 WIFI / LAN fallback (still synchronous)
                              // =======================================================
                              await billPrintByConfigType(
                                "BILL",
                                bill: activeBill,
                                kots: kotsForBill,
                                groupedItems: allItemsForBill,
                              );

                              controller.markBillPrepared(tableName);
                              showMiniSnack(
                                context,
                                "Saved",
                                "Bill saved. You can settle now.",
                                type: MiniSnackType.success,
                                maxWidth: kSnackWidth,
                                bottomGap: kSnackBottomGap,
                              );

                              debugPrint(
                                '✅ [PrintBill] ====== END Bill Print Process ======',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: _bottomTealButton(
                            isDark: isDark,
                            "Payment",
                            Icons.attach_money,
                            onTap: () async {
                              await ensureOrderSaved();

                              final kotGroups = catController.getAllKots();
                              if (kotGroups.isEmpty) {
                                Get.snackbar(
                                  "Info",
                                  "No KOT to settle",
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              final latestGroup = kotGroups.last;
                              final bill = await catController
                                  .getOrCreateBillForKot(
                                    latestGroup.items.first,
                                  );

                              // 1) Compute the live grand total for this table
                              final selectedPay =
                                  tableController.selectedTable.value;
                              final tNamePay =
                                  (selectedPay?.tableName?.trim().isNotEmpty ??
                                      false)
                                  ? selectedPay!.tableName!.trim()
                                  : controller.rxCurrentTable.value.trim();

                              final grandTotal = controller.getTotalPrice(
                                forTable: tNamePay,
                              );
                              // 2) Put it on the bill so the dialog can show it
                              bill.totalAmount = grandTotal;

                              // Optional: persist right away
                              controller.boxEntityOrder.put(bill);

                              // 3) Show dialog
                              final result = await Get.dialog<PaymentResult>(
                                PaymentDialog(bill: bill),
                                barrierDismissible: false,
                              );

                              if (result == null) return;

                              // handle attach payments in your dialog flow...
                            },
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: _bottomGreenButton(
                            "Settle Bill",
                            Icons.check_circle,
                            onTap: () async {
                              final isQuickBill =
                                  controller.rxOrderType.value
                                      .trim()
                                      .toLowerCase() ==
                                  'quick bill';

                              final selectedTable =
                                  tableController.selectedTable.value;

                              // Resolve correct table name
                              String tName = (selectedTable?.tableName ?? '')
                                  .trim();
                              if (tName.isEmpty)
                                tName = controller.rxCurrentTable.value.trim();
                              if (tName.isEmpty)
                                tName = controller.rxOrderType.value.trim();

                              if (tName.isEmpty) {
                                showMiniSnack(
                                  context,
                                  "Info",
                                  "Please select a table or order type.",
                                  type: MiniSnackType.info,
                                  maxWidth: kSnackWidth,
                                  bottomGap: kSnackBottomGap,
                                );
                                return;
                              }

                              final hasLocalCart = controller
                                  .hasUnsentItemsForTable(tName);
                              final hasServerKot = controller
                                  .hasBookedKotForTable(tName);

                              // Prevent settle when KOT is pending (except Quick Bill)
                              if (hasLocalCart && !isQuickBill) {
                                showMiniSnack(
                                  context,
                                  "KOT required",
                                  "You have pending items not sent to kitchen. Please print KOT first.",
                                  type: MiniSnackType.warning,
                                  maxWidth: kSnackWidth,
                                  bottomGap: kSnackBottomGap,
                                );
                                return;
                              }

                              if (!hasLocalCart && !hasServerKot) {
                                showMiniSnack(
                                  context,
                                  "Info",
                                  "There is nothing to settle.",
                                  type: MiniSnackType.info,
                                  maxWidth: kSnackWidth,
                                  bottomGap: kSnackBottomGap,
                                );
                                return;
                              }

                              // Require prepared bill for dine-in (except quick bill)
                              final hasPrepared = controller.hasPreparedBill(
                                tName,
                              );
                              if (!hasPrepared && !isQuickBill) {
                                showMiniSnack(
                                  context,
                                  "Save/Print required",
                                  "Please save or print the bill before settling.",
                                  type: MiniSnackType.warning,
                                  maxWidth: kSnackWidth,
                                  bottomGap: kSnackBottomGap,
                                );
                                return;
                              }

                              final customerName = controller
                                  .rxCustomerName
                                  .value
                                  .trim();
                              final customerMobile = controller
                                  .rxCustomerMobile
                                  .value
                                  .trim();
                              final customerAddress = controller
                                  .rxCustomerAddress
                                  .value
                                  .trim();
                              final waiter = controller.selectedWaiter.value;

                              // 🔥🔥 AUTO-SET DEFAULT PAYMENT MODE = CASH 🔥🔥
                              // If paymentMode is empty or null → force to "Cash"
                              String finalPaymentMode =
                                  (paymentMode.value.isEmpty)
                                  ? "Cash"
                                  : paymentMode.value;

                              // Also override if it came null from any state
                              if (finalPaymentMode.trim().isEmpty) {
                                finalPaymentMode = "Cash";
                              }

                              await controller.eBill(
                                selectedTable,
                                finalPaymentMode, // 🔥 FINAL FIX
                                customerName: customerName.isNotEmpty
                                    ? customerName
                                    : null,
                                customerMobile: customerMobile.isNotEmpty
                                    ? customerMobile
                                    : null,
                                customerAddress: customerAddress.isNotEmpty
                                    ? customerAddress
                                    : null,
                                waiterName: waiter?.userName,
                                waiterId: waiter?.userId,
                                printAfterSettle:
                                    settingController.isPrinterConnected.value,
                                includeLocalCart: isQuickBill,
                              );

                              showMiniSnack(
                                context,
                                "Settled",
                                "Bill has been settled successfully.",
                                type: MiniSnackType.success,
                                maxWidth: kSnackWidth,
                                bottomGap: kSnackBottomGap,
                              );

                              controller.markBillDirty(tName);

                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),

                        SizedBox(width: 6),
                        _smallIconButton(
                          icon: Icons.remove_red_eye_outlined,
                          onTap: () async {
                            // Get the current table name correctly.
                            final selected =
                                tableController.selectedTable.value;
                            final tableName =
                                (selected?.tableName?.trim().isNotEmpty ??
                                    false)
                                ? selected!.tableName!.trim()
                                : catController.rxCurrentTable.value.trim();

                            // --- START: MODIFIED LOGIC ---
                            // First, check if there are any items at all.
                            final hasLocalCart = controller
                                .hasUnsentItemsForTable(tableName);
                            final hasServerKot = controller
                                .hasBookedKotForTable(tableName);

                            if (!hasLocalCart && !hasServerKot) {
                              Get.snackbar(
                                "Info",
                                "Your cart is empty. Add items to preview a bill.",
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            // Now, ensure any local items are saved to the bill. This is key for Quick Bill.
                            await ensureOrderSaved();
                            // --- END: MODIFIED LOGIC ---

                            // The rest of the logic can now proceed because we know a bill with items exists.
                            final bill = catController
                                .getActiveBillForTableName(tableName);
                            if (bill == null) {
                              // This is a safety check, should not be hit now.
                              Get.snackbar(
                                "Error",
                                "Could not generate bill preview. Please try again.",
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            final List<KotGroup> kotGroups = catController
                                .getKotsForActiveBillOfTable(tableName);
                            final kotNumbers = kotGroups
                                .map((g) => g.kotNumber)
                                .toSet()
                                .toList();
                            kotNumbers.sort();

                            final groupedItems = catController
                                .getGroupedOrderItemsForKot(
                                  includeServerKot: true,
                                );

                            Get.dialog(
                              BillPreviewDialog(
                                bill: bill,
                                groupedItems: groupedItems,
                                kotNumbers: kotNumbers,
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 6),

                        const SizedBox(width: 6),
                        _smallIconButton(
                          icon: Icons.add,
                          onTap: () {
                            // plus icon logic
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _smallIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF2B2C2E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  void showDiscountDialog(BuildContext context) {
    final ControllerOrder controller = Get.find<ControllerOrder>();
    final ControllerTable tableController = Get.find<ControllerTable>();

    final TextEditingController fixedCtrl = TextEditingController();
    final TextEditingController percentCtrl = TextEditingController();

    final RxString mode = "fixed".obs; // 🔥 toggle state

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Apply Discount",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------
              // 🔵 Toggle Buttons
              // --------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Fixed (₹)"),
                    selected: mode.value == "fixed",
                    selectedColor: Colors.teal,
                    onSelected: (_) {
                      mode.value = "fixed";
                      percentCtrl.clear();
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Percent (%)"),
                    selected: mode.value == "percent",
                    selectedColor: Colors.teal,
                    onSelected: (_) {
                      mode.value = "percent";
                      fixedCtrl.clear();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --------------------
              // 🔵 FIXED INPUT
              // --------------------
              if (mode.value == "fixed")
                TextField(
                  controller: fixedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Fixed Discount (₹)",
                    hintText: "Enter amount",
                  ),
                ),

              // --------------------
              // 🔵 PERCENT INPUT
              // --------------------
              if (mode.value == "percent")
                TextField(
                  controller: percentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Percentage Discount (%)",
                    hintText: "Enter percent",
                  ),
                ),
            ],
          );
        }),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final table = tableController.selectedTable.value;
              final tableName =
                  table?.tableName ?? controller.rxCurrentTable.value;

              final bill = controller.getActiveBillForTableName(tableName);
              if (bill == null) {
                Get.snackbar("Error", "Bill not found.");
                return;
              }

              double discountAmount = 0;
              bill.discountPercent = 0;

              // 🔵 FIXED MODE
              if (mode.value == "fixed") {
                discountAmount = double.tryParse(fixedCtrl.text) ?? 0;
                bill.discountAmount = discountAmount;
              }

              // 🔵 PERCENT MODE
              if (mode.value == "percent") {
                final percent = double.tryParse(percentCtrl.text) ?? 0;
                bill.discountPercent = percent;
                discountAmount = ((bill.totalAmount ?? 0) * percent) / 100;
                bill.discountAmount = discountAmount;
              }

              // 🔥 UPDATE BILL TOTAL
              final originalTotal = controller.getTotalPrice(
                forTable: tableName,
              );
              final newTotal = originalTotal - discountAmount;

              bill.totalAmount = newTotal;
              controller.boxEntityOrder.put(bill);

              // 🔥 Forcing UI refresh
              controller.refresh();

              Get.back();
              Get.snackbar(
                "Discount Applied",
                "New Total: ₹${newTotal.toStringAsFixed(2)}",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  Widget _paymentIcon(IconData icon, String label) {
    return GestureDetector(
      onTap: () async {
        // ---------------------------------------
        // 1️⃣ DISCOUNT BUTTON HANDLING
        // ---------------------------------------
        if (label == "Discount") {
          showDiscountDialog(Get.context!);
          return;
        }

        // ---------------------------------------
        // 2️⃣ SERVICE BUTTON (waiter selection)
        // ---------------------------------------
        if (label == "Service") {
          final controllerUser = Get.put(ControllerUser());
          final serviceUsers = controllerUser.getServiceUsers();

          if (serviceUsers.isEmpty) {
            Get.snackbar(
              "No Waiters Found",
              "No Captain or Waiter available.",
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          final Rxn<EntityUser> selectedUser = Rxn<EntityUser>();
          final isDark = Get.isDarkMode;

          await Get.dialog(
            AlertDialog(
              backgroundColor: isDark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFFDFDFD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Center(
                child: Text(
                  "Select waiter",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              content: SizedBox(
                width: 300,
                height: 120,
                child: Obx(
                  () => DropdownButtonFormField<EntityUser>(
                    value: selectedUser.value,
                    dropdownColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                    decoration: InputDecoration(
                      labelText: "Select waiter",
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: serviceUsers.map((user) {
                      return DropdownMenuItem(
                        value: user,
                        child: Text(
                          user.first ?? 'Unknown',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => selectedUser.value = val,
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF2E8B57)
                        : const Color(0xFF225C45),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (selectedUser.value == null) {
                      Get.snackbar(
                        "Select Waiter",
                        "Please choose a waiter before continuing.",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    final controllerOrder = Get.find<ControllerOrder>();
                    controllerOrder.setWaiter(selectedUser.value);
                    Get.back();
                    Get.snackbar(
                      "Waiter Selected",
                      "Assigned to ${selectedUser.value?.userName ?? 'Unknown'}",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = const Color(0xFF046D6D);
          final textColor = isDark ? Colors.white70 : Colors.black87;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.teal.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentRadio(
    String label,
    RxString selected,
    String value, {
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => Radio<String>(
            value: value,
            groupValue: selected.value,
            activeColor: const Color(0xFF049A9A),
            fillColor: WidgetStateProperty.all(const Color(0xFF049A9A)),
            onChanged: (v) => selected.value = v!,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _bottomTealButton(
    String label,
    IconData icon, {
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF049A9A),
        foregroundColor: isDark ? Colors.white : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _bottomGreenButton(
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 12),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF049A9A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ---------- UI helpers ----------
  Widget _pillButton(String text, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
          color: Colors.white10,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _paymentChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF222426),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }

  Widget _bottomButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }
}

// your old dialogs, helper functions, and classes stay as-is
// (showOldKotDialog, AddNoteDialog, OldKotDialog, etc.)

Widget _buildEditableRow(
  ThemeData theme,
  int index,
  String name,
  int qty,
  double total,
  VoidCallback onRemove,
  VoidCallback onAdd,
) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: Row(
      children: [
        SizedBox(
          width: 24,
          child: Text("${index + 1}.", style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 6),
        Expanded(flex: 5, child: Text(name, overflow: TextOverflow.ellipsis)),
        Expanded(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: const Icon(Icons.remove),
                  onPressed: onRemove,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text("$qty"),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: const Icon(Icons.add),
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(total.toStringAsFixed(2), textAlign: TextAlign.right),
        ),
      ],
    ),
  );
}

Widget _buildReadonlyRow(
  ThemeData theme,
  int index,
  String name,
  int qty,
  double total,
) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: Row(
      children: [
        SizedBox(
          width: 24,
          child: Text("${index + 1}.", style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 6),
        Expanded(flex: 5, child: Text(name, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Center(child: Text("$qty"))),
        Expanded(
          flex: 3,
          child: Text(total.toStringAsFixed(2), textAlign: TextAlign.right),
        ),
      ],
    ),
  );
}

// void showOldKotDialog(BuildContext context) {
//   final ControllerOrder c = Get.find<ControllerOrder>();
//   final tableName = c.rxCurrentTable.value;
//   final kotItems = c.tableOrders[tableName]?.kotItems ?? <ExtraItem>[].obs;

//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext context) => OldKotDialog(
//       oldKots: kotItems
//           .map(
//             (e) => EntityOrderFood(
//               foodId: int.tryParse(e.id) ?? 0,
//               name: e.name,
//               price: e.price,
//               quantity: e.qty,
//               category: '',
//               taxPercentage: null,
//             ),
//           )
//           .toList(),
//     ),
//   );
// }

class AddNoteDialog extends StatefulWidget {
  final String itemName;
  const AddNoteDialog({super.key, required this.itemName});

  @override
  State<AddNoteDialog> createState() => AddNoteDialogState();
}

class AddNoteDialogState extends State<AddNoteDialog> {
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Note for ${widget.itemName}"),
      content: TextField(
        controller: _noteCtrl,
        decoration: const InputDecoration(
          hintText: "Enter note here...",
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
        FilledButton(
          onPressed: () {
            final note = _noteCtrl.text.trim();
            if (note.isNotEmpty) {
              final controller = Get.find<ControllerOrder>();
              controller.addNoteToItem(itemId: widget.itemName, note: note);
              Get.snackbar(
                "Note Added",
                note,
                snackPosition: SnackPosition.BOTTOM,
              );
            }
            Get.back();
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class OldKotDialog extends StatelessWidget {
  final List<EntityOrderFood> oldKots; // use EntityOrderFood directly
  const OldKotDialog({super.key, required this.oldKots});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = const Color(0xFF38761D);
    final Color surfaceColor = isDark ? const Color(0xFF2E2E2E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final Color borderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final Color headerBg = isDark
        ? Colors.grey.shade900
        : const Color(0xFFF7F7F7);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Old KOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TABLE HEADER
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: headerBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Item Name',
                                style: TextStyle(color: subtitleColor),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: subtitleColor),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Amount',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: subtitleColor),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'KOT',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: subtitleColor),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Select & Reason',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: subtitleColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: borderColor, thickness: 1),

                      // DYNAMIC ITEM ROWS
                      if (oldKots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              "No KOT items found.",
                              style: TextStyle(color: subtitleColor),
                            ),
                          ),
                        )
                      else
                        ...oldKots.map((item) {
                          final qty = item.quantity ?? 0;
                          final amount = (item.price ?? 0.0) * qty;
                          return Column(
                            children: [
                              _KotItemRow(
                                itemName: item.name ?? 'Unnamed',
                                qty: qty,
                                amount: amount,
                                textColor: textColor,
                                borderColor: borderColor,
                                primaryColor: primaryColor,
                              ),
                              Divider(height: 1, color: borderColor),
                            ],
                          );
                        }),

                      const SizedBox(height: 20),

                      // ACTION BUTTONS
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _ActionButton(
                              label: 'Complementary',
                              color: primaryColor,
                            ),
                            _ActionButton(label: 'Print', color: primaryColor),
                            _ActionButton(
                              label: 'Delete KOT',
                              color: primaryColor,
                            ),
                            _ActionButton(
                              label: 'Cancel KOT',
                              color: primaryColor,
                            ),
                            _ActionButton(
                              label: 'Transfer Item',
                              color: primaryColor,
                              onPressed: () => showTransferDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FOOTER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Checkbox ---
class _CustomCheckbox extends StatelessWidget {
  final String label;
  final bool isChecked;
  final Color color;
  final Color textColor;

  const _CustomCheckbox({
    required this.label,
    required this.isChecked,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: isChecked, onChanged: (_) {}, activeColor: color),
        Text(label, style: TextStyle(color: textColor, fontSize: 15)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed; // add this

  const _ActionButton({
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }
}

// --- Item Row ---
class _KotItemRow extends StatelessWidget {
  final String itemName;
  final int qty;
  final double amount;
  final Color textColor;
  final Color borderColor;
  final Color primaryColor;

  const _KotItemRow({
    required this.itemName,
    required this.qty,
    required this.amount,
    required this.textColor,
    required this.borderColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              itemName,
              style: TextStyle(fontSize: 15, color: textColor),
            ),
          ),
          Expanded(
            flex: 1,
            child: _QtySelector(
              initialQty: qty,
              color: primaryColor,
              borderColor: borderColor,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '₹${amount.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              '—',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Checkbox(value: false, onChanged: (_) {}),
                SizedBox(
                  height: 38,
                  child: TextFormField(
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Quantity Selector ---
class _QtySelector extends StatelessWidget {
  final int initialQty;
  final Color color;
  final Color borderColor;

  const _QtySelector({
    required this.initialQty,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _QtyButton(icon: Icons.remove, color: Colors.redAccent),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$initialQty',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          _QtyButton(icon: Icons.add, color: Colors.green),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _QtyButton({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

void showTransferDialog(BuildContext context) {
  final ControllerTable tableController = Get.find<ControllerTable>();
  final RxString rxSearch = ''.obs;
  final Rxn<EntityTable> selectedTable = Rxn<EntityTable>();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        return Obx(() {
          // Filter tables based on search
          final filteredTables = tableController.rxTableList.where((t) {
            final tableName = t.tableName?.toLowerCase() ?? '';
            return tableName.contains(rxSearch.value.toLowerCase());
          }).toList();

          return AlertDialog(
            title: const Text("Select Table to Transfer"),
            content: SizedBox(
              width: 400,
              height: 400,
              child: Column(
                children: [
                  // Search field
                  TextField(
                    controller: TextEditingController(text: rxSearch.value)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: rxSearch.value.length),
                      ),
                    decoration: const InputDecoration(
                      labelText: 'Search Table',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => rxSearch.value = v,
                  ),
                  const SizedBox(height: 4),

                  // Autocomplete dropdown
                  if (rxSearch.value.isNotEmpty && filteredTables.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredTables.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final table = filteredTables[index];
                          final booked = tableController.isTableBooked(
                            table.tableName,
                          );
                          return ListTile(
                            title: Text(table.tableName ?? 'Unknown'),
                            trailing: booked
                                ? const Text(
                                    'Booked',
                                    style: TextStyle(color: Colors.red),
                                  )
                                : null,
                            onTap: () {
                              if (!booked) {
                                rxSearch.value = table.tableName ?? '';
                                selectedTable.value = table;
                                setState(() {}); // refresh dropdown
                              }
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Selected table info
                  if (selectedTable.value != null)
                    Row(
                      children: [
                        const Text('Selected: '),
                        Text(
                          selectedTable.value!.tableName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedTable.value == null
                    ? null
                    : () {
                        final controllerOrder = Get.find<ControllerOrder>();
                        final fromTable = controllerOrder.rxCurrentTable.value;
                        final toTable = selectedTable.value!.tableName ?? '';

                        if (fromTable.isEmpty || toTable.isEmpty) return;

                        final fromData =
                            controllerOrder.tableOrders[fromTable]!;
                        final toData = controllerOrder.tableOrders[toTable]!;

                        // toData.kotItems.addAll(
                        //   fromData.kotItems.map((e) => e.copyWith()).toList(),
                        // );
                        fromData.kotItems.clear();

                        controllerOrder.loadTableOrders(toTable);

                        debugPrint(
                          "✅ KOT transferred from [$fromTable] to [$toTable]",
                        );
                        Navigator.pop(context);
                      },
                child: const Text('Transfer'),
              ),
            ],
          );
        });
      },
    ),
  );
}
