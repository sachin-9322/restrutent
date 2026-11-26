// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_printer.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/printer/printer_configuration.dart';
import 'package:splash_screen_03/screens/home/fragments/order/widget/activity_kot_preview.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/order/widget/fragment_kot_bill_tab.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/raw_pritner_service.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/wifi_pritner.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';

// Uses your compact, bottom-center snackbar helper
import 'package:splash_screen_03/utils/sanbar.dart';

class OrderTableContent extends StatelessWidget {
  final ThemeData theme;
  final TabController tabController;
  const OrderTableContent({
    required this.theme,
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final ControllerOrder catController = Get.isRegistered<ControllerOrder>()
        ? Get.find<ControllerOrder>()
        : Get.put(ControllerOrder());

    final ControllerTable tableController = Get.isRegistered<ControllerTable>()
        ? Get.find<ControllerTable>()
        : Get.put(ControllerTable());

    final ControllerSetting settingController =
        Get.isRegistered<ControllerSetting>()
        ? Get.find<ControllerSetting>()
        : Get.put(ControllerSetting());

    String formatMoney(ControllerSetting s, double amount) {
      return NumberFormat.currency(
        locale: s.currLocale,
        symbol: s.currSymbol,
        decimalDigits: 2,
      ).format(amount);
    }
    // Add this new widget to your OrderTableContent.dart file

    Widget buildKotHeaderRow({
      required KotGroup kot,
      required ThemeData theme,
    }) {
      final kotNumber = kot.kotNumber ?? 0;
      // Safely parse the date and format it
      DateTime createdTime;
      try {
        createdTime = DateTime.parse(kot.createdOn ?? '');
      } catch (_) {
        createdTime = DateTime.now(); // Fallback to now if parsing fails
      }
      final formattedTime = DateFormat('hh:mm a').format(createdTime.toLocal());

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(top: 12, left: 8, right: 8, bottom: 4),
        decoration: BoxDecoration(
          // Use a color that stands out slightly
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KOT #$kotNumber',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'Printed at: $formattedTime',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final RxString paymentMode = "Cash".obs;

    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark
        ? const Color(0xFF0E1113)
        : theme.colorScheme.surface;

    // Add a state variable to your widget's build method or state class
    // to prevent double-taps.
    bool isPrinting = false;

    const double kSnackWidth = 320;
    const double kSnackBottomGap = 18;

    return SafeArea(
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  child: Text(
                    "Sr",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 5,
                  child: Text(
                    "Item Name",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Qty",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Amount",
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 6),

          // List area
          // Inside your OrderTableContent build():
          Expanded(
            child: Obx(() {
              final normalCount = catController.rxOrderItems.length;
              final extrasCount = catController.rxExtraItems.length;

              // Take a snapshot of rxKotItems to keep length consistent during build
              final rxKotSnapshot = List.of(catController.rxKotItems.reversed);
              final serverCount = rxKotSnapshot.length;

              final totalCount = normalCount + extrasCount + serverCount;

              if (totalCount == 0) {
                return Center(
                  child: Text(
                    "Your cart is empty",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                itemCount: totalCount,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  // --- Local normal food items (editable) ---
                  if (index < normalCount) {
                    final food = catController.rxOrderItems.keys.elementAt(
                      index,
                    );
                    final qty = catController.rxOrderItems[food]!;
                    final price = food.price.isNotEmpty
                        ? (food.price.first.price ?? 0.0)
                        : 0.0;
                    final total = price * qty;

                    return _buildEditableRow(
                      index: index,
                      title: food.foodName ?? "Unnamed Food",
                      qtyStr: "$qty",
                      amountStr: total.toStringAsFixed(2),
                      theme: theme,
                      onRemove: () => catController.decreaseQuantity(food),
                      onAdd: () => catController.increaseQuantity(food),
                    );
                  }

                  // --- Local extra items (editable) ---
                  if (index < normalCount + extrasCount) {
                    final eIndex = index - normalCount;
                    final ex = catController.rxExtraItems[eIndex];
                    final total = ex.price * ex.qty;
                    return _buildEditableRow(
                      index: index,
                      title: ex.name,
                      qtyStr: "${ex.qty}",
                      amountStr: total.toStringAsFixed(2),
                      theme: theme,
                      onRemove: () => catController.decreaseExtraQty(ex.id),
                      onAdd: () => catController.increaseExtraQty(ex.id),
                      isExtra: true,
                    );
                  }

                  // --- ✅ Server/persisted KOT items (read-only with KOT header strip) ---
                  final sIndex = index - normalCount - extrasCount;
                  if (sIndex < 0 || sIndex >= rxKotSnapshot.length) {
                    return const SizedBox.shrink();
                  }

                  final serverItem = rxKotSnapshot[sIndex];
                  final serverTotal = (serverItem.price) * (serverItem.qty);

                  // Determine if we should show KOT header before this row
                  final bool showHeader =
                      (sIndex == 0) ||
                      (rxKotSnapshot[sIndex - 1].kotNumber !=
                          serverItem.kotNumber);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showHeader)
                        buildKotHeaderRow(
                          kot: KotGroup(
                            kotNumber: serverItem.kotNumber ?? 0,
                            createdOn:
                                serverItem.createdOn ??
                                DateTime.now().toIso8601String(),
                            tableName: serverItem.tableName ?? '',
                            items: [], // only for header display
                          ),
                          theme: theme,
                        ),
                      _buildReadOnlyRow(
                        index: index,
                        title: serverItem.name,
                        qtyStr: "${serverItem.qty}",
                        amountStr: serverTotal.toStringAsFixed(2),
                        theme: theme,
                        onCancel: () => catController.removeKotItem(serverItem),
                      ),
                    ],
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 8),

          // Bottom Action Bar (sticky)
          Obx(() {
            final bool isConnected = settingController.isPrinterConnected.value;
            final bool isQuick =
                catController.rxOrderType.value == "Quick Bill";
            final bool settled = catController.rxBillSettled.value;

            return Container(
              color: isDark ? Color(0xFF046D6D) : Color(0xFF046D6D),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  // Left: total block with label
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          "Total:",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final total = catController.getTotalPrice(
                            forTable: catController.rxCurrentTable.value,
                          );
                          return Text(
                            formatMoney(settingController, total),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Right: action icons row
                  Row(
                    children: [
                      // Preview KOT
                      ActionCircleButton(
                        tooltip: "Preview KOT",
                        icon: Icons.remove_red_eye_outlined,
                        onPressed: () async {
                          final selected = tableController.selectedTable.value;
                          final tableName =
                              (selected?.tableName?.trim().isNotEmpty ?? false)
                              ? selected!.tableName!.trim()
                              : (catController.rxOrderType.value == "Dine-In"
                                    ? "Quick Bill"
                                    : catController.rxOrderType.value);

                          final groupedItems = catController
                              .getGroupedOrderItemsForKot(
                                includeServerKot: true,
                              );

                          final hasLocalItems =
                              (groupedItems['Local']?.isNotEmpty ?? false) ||
                              (groupedItems['Extras']?.isNotEmpty ?? false);

                          if (!hasLocalItems) {
                            showMiniSnack(
                              context,
                              "Info",
                              "No new items in the cart to preview.",
                              type: MiniSnackType.info,
                              maxWidth: kSnackWidth,
                              bottomGap: kSnackBottomGap,
                            );
                            return;
                          }

                          EntityOrder? bill = catController
                              .getActiveBillForTableName(tableName);

                          bill ??= await catController
                              .createBillWithoutOrderNumber(
                                tableName,
                                selected?.seats ?? 0,
                              );

                          final virtualKot = KotGroup(
                            kotNumber: 0,
                            createdOn: DateTime.now().toIso8601String(),
                            tableName: tableName,
                            items: [],
                          );

                          await Get.dialog(
                            KotPreviewDialog(
                              kot: virtualKot,
                              bill: bill,
                              groupedItems: groupedItems,
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 8),

                      // Save KOT (when printer not connected) OR Print KOT
                      ActionCircleButton(
                        tooltip: "Print KOT",
                        icon: Icons.print,
                        onPressed: () async {
                          if (catController.isPrintingKot.value) {
                            showMiniSnack(
                              context,
                              "Printing...",
                              "A print job is already in progress.",
                              type: MiniSnackType.info,
                              maxWidth: kSnackWidth,
                              bottomGap: kSnackBottomGap,
                            );
                            return;
                          }
                          catController.isPrintingKot.value = true;

                          try {
                            // --- Resolve table name (this part is fine)
                            final physicalTable =
                                tableController.selectedTable.value;
                            final tempTable =
                                tableController.selectedTempTable.value;
                            String tableName = '';

                            if (physicalTable != null &&
                                (physicalTable.tableName?.trim().isNotEmpty ??
                                    false)) {
                              tableName = physicalTable.tableName!;
                            } else if (tempTable != null) {
                              tableName = tempTable.name;
                            } else {
                              tableName = catController.rxCurrentTable.value;
                            }
                            tableName = tableName.trim();

                            if (tableName.isEmpty) {
                              showMiniSnack(
                                context,
                                "Info",
                                "Please select a table or add an item first.",
                                type: MiniSnackType.info,
                                maxWidth: kSnackWidth,
                                bottomGap: kSnackBottomGap,
                              );
                              return;
                            }

                            final int seats =
                                physicalTable?.seats ?? tempTable?.seats ?? 0;

                            // --- Always save KOT first (this returns the NEW KOT group)
                            final KotGroup? latestGroup = await catController
                                .ensureKotForTable(
                                  tableName: tableName,
                                  tableSeat: seats,
                                );

                            if (latestGroup == null ||
                                (latestGroup.items.isEmpty)) {
                              showMiniSnack(
                                context,
                                "Info",
                                "No new items in the cart to print.", // More accurate message
                                type: MiniSnackType.info,
                                maxWidth: kSnackWidth,
                                bottomGap: kSnackBottomGap,
                              );
                              return;
                            }

                            EntityOrder? bill = catController
                                .getActiveBillForTableName(tableName);

                            bill ??= await catController
                                .createBillWithoutOrderNumber(tableName, seats);

                            // ================== ✅ THE FIX IS HERE ==================
                            // DO NOT re-fetch all items. Instead, build a map using ONLY the items
                            // from the `latestGroup` that was just created.

                            final Map<String, List<MapEntry<dynamic, int>>>
                            itemsForThisKotOnly = {};

                            // The `latestGroup.items` contains the list of `EntityOrderFood` we just saved.
                            for (final newItem in latestGroup.items) {
                              final category = newItem.category ?? 'Main';
                              // Ensure the category list exists
                              itemsForThisKotOnly.putIfAbsent(
                                category,
                                () => [],
                              );
                              // Add the new item to the map
                              // If newItem.quantity is null, use 1 as a safe default.
                              itemsForThisKotOnly[category]!.add(
                                MapEntry(newItem, newItem.quantity ?? 1),
                              );
                            }
                            // ================== END OF FIX ==================

                            // --- Check printer configuration (this part is fine)
                            final Box<EntityPrinter> printerBox = Get.find();
                            final q = printerBox
                                .query(EntityPrinter_.configType.equals('KOT'))
                                .build();
                            final pr = q.findFirst();
                            q.close();

                            if (pr == null) {
                              // No printer configured, just show saved message
                              showMiniSnack(
                                context,
                                "KOT Saved",
                                "No printer configured. KOT saved successfully.",
                                type: MiniSnackType.info,
                                maxWidth: kSnackWidth,
                                bottomGap: kSnackBottomGap,
                              );
                              // After saving, we clear the local cart and refresh the UI.
                              catController.markKotGroupPrinted(
                                bill,
                                latestGroup,
                              );
                              catController.refreshKotItemsForTable(
                                tableName,
                                bill.orderId,
                              );
                              catController.rebuildUnifiedKotList(
                                tableName: tableName,
                              );
                              tabController.animateTo(1);
                              return;
                            }

                            // --- Check connection status (this part is fine)
                            final url = (pr.printUrl ?? '').toLowerCase();
                            final isBluetooth =
                                url.startsWith('bluetooth://') ||
                                url.contains('bluetooth');
                            final copies = (pr.noOfCop ?? 1).clamp(1, 10);
                            bool printerReady = false;

                            if (isBluetooth) {
                              final bt = Get.put(
                                RawBtPrinterService(),
                                permanent: true,
                              );
                              printerReady = await bt.refreshConnectionStatus();
                              if (!printerReady) {
                                showMiniSnack(
                                  context,
                                  "Saved Only",
                                  "Bluetooth printer not connected. KOT saved successfully.",
                                  type: MiniSnackType.warning,
                                  maxWidth: kSnackWidth,
                                  bottomGap: kSnackBottomGap,
                                );
                                catController.markKotGroupPrinted(
                                  bill,
                                  latestGroup,
                                );
                                catController.refreshKotItemsForTable(
                                  tableName,
                                  bill.orderId,
                                );
                                catController.rebuildUnifiedKotList(
                                  tableName: tableName,
                                );
                                tabController.animateTo(1);
                                return;
                              }
                            } else {
                              printerReady = true; // WiFi/USB assumed ready
                            }

                            if (!printerReady) {
                              // General "not ready" message
                              showMiniSnack(
                                context,
                                "Saved Only",
                                "Printer not connected. KOT saved successfully.",
                                type: MiniSnackType.warning,
                                maxWidth: kSnackWidth,
                                bottomGap: kSnackBottomGap,
                              );
                              catController.markKotGroupPrinted(
                                bill,
                                latestGroup,
                              );
                              catController.refreshKotItemsForTable(
                                tableName,
                                bill.orderId,
                              );
                              catController.rebuildUnifiedKotList(
                                tableName: tableName,
                              );
                              tabController.animateTo(1);
                              return;
                            }

                            // ✅ Printer connected: print now
                            for (int i = 0; i < copies; i++) {
                              await Get.find<RawBtPrinterService>()
                                  .printKotEscPosByConfigType(
                                    configType: 'KOT',
                                    kot: latestGroup,
                                    bill: bill,
                                    // Pass the NEW, CORRECTLY-SCOPED map to the print function
                                    groupedItems: itemsForThisKotOnly,
                                  );
                            }

                            // Clean up and refresh UI
                            catController.markKotGroupPrinted(
                              bill,
                              latestGroup,
                            );
                            catController.refreshKotItemsForTable(
                              tableName,
                              bill.orderId,
                            );
                            catController.rebuildUnifiedKotList(
                              tableName: tableName,
                            );

                            showMiniSnack(
                              context,
                              "Printed",
                              "KOT #${latestGroup.kotNumber} sent for printing.",
                              type: MiniSnackType.success,
                              maxWidth: kSnackWidth,
                              bottomGap: kSnackBottomGap,
                            );
                            tabController.animateTo(1);
                          } catch (e, st) {
                            showMiniSnack(
                              context,
                              "Print Failed",
                              "Error: ${e.toString()}",
                              type: MiniSnackType.error,
                              maxWidth: kSnackWidth,
                              bottomGap: kSnackBottomGap,
                            );
                            debugPrint('KOT print error: $e\n$st');
                          } finally {
                            catController.isPrintingKot.value = false;
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

Widget _buildEditableRow({
  required int index,
  required String title,
  required String qtyStr,
  required String amountStr,
  required ThemeData theme,
  required VoidCallback onRemove,
  required VoidCallback onAdd,
  bool isExtra = false,
  String? note,
}) {
  final bgColor = isExtra
      ? Colors.teal.withOpacity(0.08)
      : Colors.grey.withOpacity(0.06);

  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        // 🔹 Index
        Text(
          "${index + 1}.",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),

        // 🔹 Item Name + Note
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (note != null && note.isNotEmpty)
                Text(
                  "($note)",
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        // 🔹 Qty controls
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onRemove,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  qtyStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.greenAccent,
                  size: 22,
                ),
              ),
            ],
          ),
        ),

        // 🔹 Amount
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                amountStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildReadOnlyRow({
  required int index,
  required String title,
  required String qtyStr,
  required String amountStr,
  required ThemeData theme,
  VoidCallback? onCancel,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange.withOpacity(0.25), width: 1),
    ),
    child: Row(
      children: [
        // 🔹 Index
        Text(
          "${index + 1}.",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),

        // 🔹 Item Name + print icon
        Expanded(
          flex: 5,
          child: Row(
            children: [
              const Icon(
                Icons.print_rounded,
                color: Colors.orangeAccent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 🔹 Quantity
        Expanded(
          flex: 2,
          child: Text(
            qtyStr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 🔹 Amount (no cancel/delete)
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              amountStr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Small circular action button used in bottom bar
class ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const ActionCircleButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark ? Colors.black.withOpacity(0.18) : Colors.white24);
    final ic = iconColor ?? (isDark ? Colors.white : Colors.black87);

    return Tooltip(
      message: tooltip ?? "",
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: ic),
          ),
        ),
      ),
    );
  }
}
