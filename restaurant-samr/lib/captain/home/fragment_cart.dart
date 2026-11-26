// ignore_for_file: dead_code

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
Uint8List? _decodeBase64Image(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    final src = s.startsWith('data:image') ? s.split(',').last : s;
    return base64Decode(src.replaceAll('\n', '').replaceAll('\r', ''));
  } catch (_) {
    return null;
  }
}

Uint8List? _tryGetFoodImageBytes(dynamic food) {
  // Try to get from the 'images' list first
  try {
    if (food.images != null &&
        food.images is List &&
        (food.images as List).isNotEmpty) {
      final first = (food.images as List).first;
      if (first is String && first.trim().isNotEmpty) {
        final b = _decodeBase64Image(first);
        if (b != null) return b;
      }
    }
  } catch (_) {}

  // Fallback to 'imgPath'
  try {
    final String? path = food.imgPath;
    final b = _decodeBase64Image(path);
    if (b != null) return b;
  } catch (_) {}

  return null;
}
class CartScreen extends StatelessWidget {
  final ControllerOrder controller;
  const CartScreen({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final ControllerTable tableController = Get.isRegistered<ControllerTable>()
        ? Get.find<ControllerTable>()
        : Get.put(ControllerTable());

    // Helpers
    double safeDouble(num? v) => (v ?? 0).toDouble();

    double unitPriceOfFood(dynamic food) {
      // Prefer offerPrice -> price -> mrp if available
      try {
        if (food.price != null && food.price.isNotEmpty) {
          final p = food.price.first;
          final n = safeDouble(p.offerPrice ?? p.price ?? p.mrp ?? 0);
          return n.isFinite ? n : 0;
        }
      } catch (_) {}
      return 0;
    }

    Widget tableChip() {
      return Obx(() {
        final selectedTable = tableController.selectedTable.value;
        final tableName = (selectedTable?.tableName ??
                controller.rxCurrentTable.value)
            .trim();
        if (tableName.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Chip(
            label: Text(tableName, style: const TextStyle(fontWeight: FontWeight.w600)),
            avatar: const Icon(Icons.table_restaurant, size: 18),
            backgroundColor: color.secondaryContainer,
            labelStyle: TextStyle(color: color.onSecondaryContainer),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      });
    }

    Future<int?> askSeats(BuildContext ctx) async {
      final ctrl = TextEditingController(text: '1');
      return showDialog<int>(
        context: ctx,
        builder: (ctx) => AlertDialog(
          title: const Text('Enter seats'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Number of seats'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final s = int.tryParse(ctrl.text.trim());
                if (s == null || s <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid number')),
                  );
                  return;
                }
                Navigator.pop(ctx, s);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor:const Color(0xFF005D6A),
        titleSpacing: 0,
        title: Row(
          children: [
            const Text("Your Cart", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),),
            tableChip(),
          ],
        ),
      ),
      body: Obx(() {
        final entries = controller.rxOrderItems.entries.toList();
        final extras = controller.rxExtraItems.toList();

        // Totals
        double total = 0;
        for (final entry in entries) {
          final food = entry.key;
          final qty = entry.value;
          final unit = unitPriceOfFood(food);
          total += unit * (qty <= 0 ? 0 : qty);
        }
        for (final ex in extras) {
          final unit = safeDouble(ex.price);
          final qty = ex.qty <= 0 ? 0 : ex.qty;
          total += unit * qty;
        }

        final hasItems = entries.isNotEmpty || extras.isNotEmpty;

        if (!hasItems) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: theme.disabledColor),
                const SizedBox(height: 12),
                const Text("Your cart is empty", style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: entries.length + extras.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i < entries.length) {
                    final food = entries[i].key;
                    final qty = entries[i].value;
                    final unitPrice = unitPriceOfFood(food);
                    final lineTotal = unitPrice * (qty <= 0 ? 0 : qty);

                    return _CartItemCard(
                      title: food.foodName ?? "Item",
                      unitPrice: unitPrice,
                      qty: qty,
                      lineTotal: lineTotal,
                      color: color,
                      onIncrease: () {
                        try {
                          controller.increaseQuantity(food);
                        } catch (e) {
                          Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                      onDecrease: () async {
                        try {
                          if (qty <= 1) {
                            final confirm = await _confirmRemove(context, color);
                            if (confirm != true) return;
                          }
                          controller.decreaseQuantity(food);
                        } catch (e) {
                          Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                    );
                  }

                  final ex = extras[i - entries.length];
                  final unit = safeDouble(ex.price);
                  final qty = ex.qty;
                  final lineTotal = unit * (qty <= 0 ? 0 : qty);

                  return _CartItemCard(
                    title: ex.name,
                    unitPrice: unit,
                    qty: qty,
                    lineTotal: lineTotal,
                    color: color,
                    onIncrease: () {
                      try {
                        controller.increaseExtraQty(ex.id);
                      } catch (e) {
                        Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    onDecrease: () async {
                      try {
                        if (qty <= 1) {
                          final confirm = await _confirmRemove(context, color);
                          if (confirm != true) return;
                        }
                        controller.decreaseExtraQty(ex.id);
                      } catch (e) {
                        Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                  );
                },
              ),
            ),

            // Footer - Total + Send KOT
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                children: [
                  // Totals row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        total.toStringAsFixed(2),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Send KOT
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() {
                      final isLoading = controller.isPrintingKot.value;
                      final disabled = isLoading || !hasItems;
                      return ElevatedButton.icon(
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.receipt_long),
                        label: Text(isLoading ? "Sending..." : "Send KOT"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: disabled ? color.primary.withOpacity(0.5) : color.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: disabled
                            ? null
                            : () async {
                                controller.isPrintingKot.value = true;
                                try {
                                  final selectedTable = tableController.selectedTable.value;
                                  String tableName = (selectedTable?.tableName ??
                                          controller.rxCurrentTable.value)
                                      .trim();

                                  if (tableName.isEmpty) {
                                    Get.snackbar(
                                      "Select table",
                                      "Please select a table first.",
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }

                                  int seats = selectedTable?.seats ?? 0;
                                  if (seats <= 0) {
                                    final s = await askSeats(context);
                                    if (s == null) return; // cancelled
                                    seats = s;
                                  }

                                  await controller.saveOrder(tableName, seats, "booked");

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Order sent / KOT created')),
                                    );
                                  }
                                } catch (e) {
                                  Get.snackbar("Error", e.toString(),
                                      snackPosition: SnackPosition.BOTTOM);
                                } finally {
                                  controller.isPrintingKot.value = false;
                                }
                              },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context, ColorScheme color) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item'),
        content: const Text('Do you want to remove this item from the cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
  }
}
class _CartItemCard extends StatelessWidget {
  final String title;
  final int qty;
  final double unitPrice;
  final double lineTotal;
  final ColorScheme color;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final Uint8List? imgBytes; // <-- ADD THIS

  const _CartItemCard({
    required this.title,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.color,
    required this.onIncrease,
    required this.onDecrease,
    this.imgBytes, // <-- ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // --- MODIFIED THUMBNAIL ---
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 50,
                height: 50,
                color: theme.colorScheme.tertiaryContainer,
                child: imgBytes != null
                    ? Image.memory( 
                        imgBytes!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : Icon( // Fallback to icon
                        Icons.fastfood,
                        size: 28,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
              ),
            ),
            // --- END OF MODIFICATION ---
            const SizedBox(width: 12),

            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    "Unit: ${unitPrice.toStringAsFixed(2)} • Total: ${lineTotal.toStringAsFixed(2)}",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),

            // Stepper (remains the same)
            Row(
              children: [
                IconButton(
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: color.primary,
                  splashRadius: 20,
                  tooltip: 'Decrease',
                ),
                Container(
                  width: 36,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    qty.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add_circle_outline),
                  color: color.primary,
                  splashRadius: 20,
                  tooltip: 'Increase',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}