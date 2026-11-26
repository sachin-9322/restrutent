// lib/screens/home/fragments/order/top_header_bar_exact.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';

import 'package:splash_screen_03/screens/home/fragments/order/fragment_order.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/sub_order_type/controller_sub_order.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/fragment_table_order.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

class TopHeaderBarExact extends StatelessWidget {
  const TopHeaderBarExact({
    super.key,
    required this.tableController,
    required this.orderController,
    required this.settingController,
    required this.subController,
  });

  final ControllerTable tableController;
  final ControllerOrder orderController;
  final ControllerSetting settingController;
  final ControllerSubOrder subController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bool isMobile = width < 700;
        final bool isTablet = width >= 700 && width < 1100;
        final bool isDesktop = width >= 1100;

        final horizontalPadding = isMobile ? 8.0 : 16.0;
        final verticalPadding = isMobile ? 8.0 : 12.0;

        return GlasssCard(
          borderRadius: 16,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // LEFT SIDE FILTERS
                  Obx(() {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DropChip<String>(
                          label: 'Status',
                          value: tableController.bookingStatusFilter.value,
                          items: const ['All', 'Booked', 'Available'],
                          onSelected: (v) =>
                              tableController.bookingStatusFilter.value = v,
                          dark: isDark,
                        ),
                        if (!isMobile) const SizedBox(width: 12),
                        if (isMobile) const SizedBox(width: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Obx(() {
                            final rooms = tableController.roomNames;

                            if (rooms.length <= 1) {
                              return const SizedBox.shrink();
                            }

                            String selected = tableController.roomFilter.value;
                            if (!rooms.contains(selected)) {
                              selected = 'All';
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!tableController.isClosed) {
                                  tableController.roomFilter.value = 'All';
                                }
                              });
                            }

                            return Padding(
                              padding: EdgeInsets.only(left: isMobile ? 8 : 0),
                              child: _AcNonAcTabs(
                                types: rooms,
                                value: selected,
                                onChanged: (v) {
                                  tableController.roomFilter.value = v;
                                  if (tableController.acFilter.value != 'All') {
                                    tableController.acFilter.value = 'All';
                                  }
                                },
                                dark: isDark,
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  }),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: _QuickActionsSegment(
                          onQuickBill: () {
                            final t = _findOrderType("Quick Bill");
                            _startTempOrder(
                              context: context,
                              orderController: orderController,
                              tableController: tableController,
                              settingController: settingController,
                              subController: subController,
                               typeId: t["mongoId"]!,
                              typeLabel: t["label"]!,
                            );
                          },
                          onDelivery: () {
                            final t = _findOrderType("Delivery");
                            _startTempOrder(
                              context: context,
                              orderController: orderController,
                              tableController: tableController,
                              settingController: settingController,
                              subController: subController,
                              typeId: t["mongoId"]!,
                              typeLabel: t["label"]!,
                            );
                          },
                          onPickup: () {
                            final t = _findOrderType("Takeaway");
                            _startTempOrder(
                              context: context,
                              orderController: orderController,
                              tableController: tableController,
                              settingController: settingController,
                              subController: subController,
                             typeId: t["mongoId"]!,
                              typeLabel: t["label"]!,
                            );
                          },
                          dark: isDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () => showColorKeyDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------- DROP CHIP -------------------- //
class _DropChip<T> extends StatelessWidget {
  const _DropChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
    required this.dark,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onSelected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF1F2428) : const Color(0xFFEDEFF2);
    final fg = dark ? Colors.white : Colors.black87;

    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      color: dark ? const Color(0xFF272C31) : Colors.white,
      itemBuilder: (ctx) => [
        for (final it in items) PopupMenuItem<T>(value: it, child: Text('$it')),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: MediaQuery.of(context).size.width < 700 ? 13 : 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: fg, size: 18),
          ],
        ),
      ),
    );
  }
}

// -------------------- AC/NON-AC TABS -------------------- //
class _AcNonAcTabs extends StatelessWidget {
  const _AcNonAcTabs({
    required this.value,
    required this.types,
    required this.onChanged,
    required this.dark,
  });

  final String value;
  final List<String> types;
  final ValueChanged<String> onChanged;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (dark) {
      final buttonBg = const Color(0xFF2B3035);
      final selectedBorderColor = theme.colorScheme.primary;

      Widget seg(String text) {
        final selected = value == text;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 24,
              vertical: isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: buttonBg.withOpacity(selected ? 0.7 : 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? selectedBorderColor
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        );
      }

      return Wrap(
        spacing: isMobile ? 6 : 10,
        children: [for (final type in types) seg(type)],
      );
    } else {
      final containerBg = const Color(0xFFEDEFF2).withOpacity(0.9);
      final selectedBg = const Color(0xFF005D6A);
      final selectedFg = Colors.white;
      final unselectedFg = Colors.black87;

      Widget seg(String text) {
        final selected = value == text;
        return Material(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(text),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 24,
                vertical: isMobile ? 8 : 10,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: selected ? selectedFg : unselectedFg,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12.withOpacity(0.05)),
        ),
        child: Wrap(
          spacing: isMobile ? 6 : 10,
          children: [for (final type in types) seg(type)],
        ),
      );
    }
  }
}

// -------------------- QUICK ACTIONS -------------------- //
class _QuickActionsSegment extends StatelessWidget {
  const _QuickActionsSegment({
    required this.onQuickBill,
    required this.onDelivery,
    required this.onPickup,
    required this.dark,
  });

  final VoidCallback onQuickBill;
  final VoidCallback onDelivery;
  final VoidCallback onPickup;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final segBg = dark
        ? const Color(0xFF0E1418).withOpacity(0.6)
        : const Color(0xFFF5F7F9).withOpacity(0.8);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: BoxDecoration(
        color: segBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dark
              ? const Color(0xFF1C2A30).withOpacity(0.4)
              : const Color(0xFFE6E8EA).withOpacity(0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 4 : 6,
      ),
      child: Wrap(
        spacing: isMobile ? 4 : 6,
        children: [
          _segBtn(
            context,
            label: 'Quick Bill',
            icon: Icons.shopping_cart,
            bg: const Color(0xFF005D6A),
            fg: Colors.white,
            onTap: onQuickBill,
            isMobile: isMobile,
          ),
          _segBtn(
            context,
            label: 'Delivery',
            icon: Icons.delivery_dining,
            bg: dark ? const Color(0xFF1F2428) : const Color(0xFFEDEFF2),
            fg: dark ? Colors.white : Colors.black87,
            onTap: onDelivery,
            isMobile: isMobile,
          ),
          _segBtn(
            context,
            label: 'Takeaway',
            icon: Icons.shopping_bag_outlined,
            bg: dark ? const Color(0xFF1F2428) : const Color(0xFFEDEFF2),
            fg: dark ? Colors.white : Colors.black87,
            onTap: onPickup,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _segBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Material(
      color: bg.withOpacity(0.95),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: isMobile ? 6 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: isMobile ? 16 : 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, String> _findOrderType(String name) {
  final c = Get.find<ControllerOrderType>();

  // Quick Bill (local)
  if (name.toLowerCase() == "quick bill") {
    return {
      "id": "local-quickbill",
      "label": "Quick Bill",
      "mongoId": "000000000000000000000000",
    };
  }

  final match = c.rxOrderTypes.firstWhereOrNull((e) {
    final n = e["name"]?["en"]?.toString().trim().toLowerCase() ?? "";
    return n == name.toLowerCase();
  });

  if (match == null) {
    return {"id": "", "label": name, "mongoId": ""};
  }

  return {
    "id": match["_id"], // local id
    "label": match["name"]["en"],
    "mongoId": match["_id"], // ⭐ CRITICAL — backend orderTypeId
  };
}

String generateFakeMongoId() {
  const chars = 'abcdef0123456789';
  final ms = DateTime.now().microsecondsSinceEpoch.toString();

  return List.generate(24, (i) {
    final idx = ms.codeUnitAt(i % ms.length) % chars.length;
    return chars[idx];
  }).join();
}

Future<void> _startTempOrder({
  required BuildContext context,
  required ControllerOrder orderController,
  required ControllerTable tableController,
  required ControllerSetting settingController,
  required ControllerSubOrder subController,
  required String typeId,
  required String typeLabel,
}) async {
  // STEP 1 → Apply order type ID + label
  orderController.selectOrderTypeById(
    id: typeId, // MUST BE the MongoDB ID
    label: typeLabel,
  );

  // STEP 2 → Clear old table reference
  orderController.rxCurrentTable.value = "";

  // STEP 3 → Create temporary virtual table
  tableController.createAndSelectTempTable(typeLabel);

  final tempTable = tableController.selectedTempTable.value;

  // ⭐ STEP 3B — IMPORTANT FIX
  // Assign a valid MongoDB-like ObjectId for tableId (Delivery/Takeaway/Quick Bill)
  if (tempTable != null) {
    tempTable.mongoId = typeId; // orderTypeId (unchanged)
    tempTable.tableMongoId = generateFakeMongoId(); // <--- NEW
    orderController.loadTableOrders(tempTable.name);
  }

  // STEP 4 → Sub Order Type selection dialog
  final bool settingEnabled = settingController.saveOrderTypeEnabled.value;
  final int subCount = subController.rxOrderList.length;

  if (settingEnabled && subCount > 1) {
    String? selected =
        subController.rxOrderList.first.name?.trim() ?? "Unnamed";

    final chosen = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Select Sub Order Type"),
          content: DropdownButtonFormField<String>(
            value: selected,
            items: subController.rxOrderList.map((s) {
              return DropdownMenuItem<String>(
                value: s.name?.trim(),
                child: Text(s.name ?? "Unnamed"),
              );
            }).toList(),
            onChanged: (val) => selected = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (chosen != null && chosen.trim().isNotEmpty) {
      orderController.selectOrderTypeById(id: typeId, label: chosen.trim());
    }
  }

  // STEP 5 → Decide initial tab
  final initialIndex = typeLabel.toLowerCase() == "quick bill" ? 1 : 0;

  // Go to menu screen
  Get.to(() => ActivityCategoryFood(initialTabIndex: initialIndex));
}
