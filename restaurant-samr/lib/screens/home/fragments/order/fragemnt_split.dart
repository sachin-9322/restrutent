import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
// Corrected import path assuming your controller is in 'controller_split.dart'
import 'package:splash_screen_03/screens/home/fragments/order/controller_split.dart';

// --- Data Models (Keep these as they are) ---
class SplitDragItem {
  final String id;
  final String name;
  final int quantity;
  final bool isExtra;
  final dynamic food;
  final dynamic extra;
  final double? price;

  const SplitDragItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isExtra,
    this.food,
    this.extra,
    this.price,
  });

  SplitDragItem copyWith({
    String? id,
    String? name,
    int? quantity,
    bool? isExtra,
    dynamic food,
    dynamic extra,
    double? price,
  }) {
    return SplitDragItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isExtra: isExtra ?? this.isExtra,
      food: food ?? this.food,
      extra: extra ?? this.extra,
      price: price ?? this.price,
    );
  }
}

class PartPayment {
  final String id;
  final String mop;
  final double amount;
  PartPayment({required this.id, required this.mop, required this.amount});
  Map<String, dynamic> toJson() => {'id': id, 'mop': mop, 'amount': amount};
}

enum SplitMode { items, person, percent }

// The View is now a standard StatelessWidget
class SplitScreenPage extends StatelessWidget {
  // CHANGED from GetView
  const SplitScreenPage({super.key});

  Future<bool> _onWillPop(SplitScreenController controller) async {
    controller.navigateHome();
    return false;
  }

  Color _tileBg(SplitDragItem item, ColorScheme scheme) =>
      item.isExtra ? scheme.secondary : scheme.primary;
  Color _tileFg(SplitDragItem item, ColorScheme scheme) =>
      item.isExtra ? scheme.onSecondary : scheme.onPrimary;

  @override
  Widget build(BuildContext context) {
    // THIS IS THE FIX: We are "putting" the controller into memory here.
    // GetX is smart enough to only do this once for this screen.
    final SplitScreenController controller = Get.put(SplitScreenController());

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () => _onWillPop(controller),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Split Screen"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: controller.navigateHome,
          ),
          actions: [
            IconButton(
              tooltip: 'Go Home',
              icon: const Icon(Icons.home),
              onPressed: controller.navigateHome,
            ),
          ],
          // The TabBar needs to be wrapped in an Obx to react to mode changes
          bottom: TabBar(
            controller: controller.tabController,
            onTap: controller.onTabSelected, // Let controller handle taps
            tabs: const [
              Tab(text: 'By Items'),
              Tab(text: 'By Person'),
              Tab(text: 'By %'),
            ],
          ),
        ),
        body: Obx(
          () => Row(
            children: [
              if (controller.currentMode.value == SplitMode.items)
                buildLeftKotPane(theme, controller), // Pass controller
              buildRightPane(
                theme,
                scheme,
                isDark,
                controller,
              ), // Pass controller
            ],
          ),
        ),
      ),
    );
  }

  // NOTE: All helper methods now need the `controller` passed to them.

  Widget buildLeftKotPane(ThemeData theme, SplitScreenController controller) {
    final scheme = theme.colorScheme;
    return Expanded(
      flex: 1,
      child: Container(
        color: scheme.surfaceVariant,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Text(
                    "KOT Items (Booked)",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    final orderController = Get.find<ControllerOrder>();
                    final tables = orderController.tableOrders.keys.toList()
                      ..sort();
                    final current =
                        orderController.rxCurrentTable.value.isNotEmpty
                        ? orderController.rxCurrentTable.value
                        : (tables.isNotEmpty ? tables.first : null);

                    return DropdownButton<String>(
                      value: current,
                      hint: const Text("Select Table"),
                      items: tables
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) orderController.loadTableOrders(val);
                      },
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final items = controller.availableKotItems;
                if (Get.find<ControllerOrder>().tableOrders.isEmpty) {
                  return Center(
                    child: Text(
                      "No booked tables",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      "No items to split",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final bg = _tileBg(item, scheme);
                    final fg = _tileFg(item, scheme);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Draggable<SplitDragItem>(
                        data: item,
                        feedback: _buildDraggableFeedback(
                          item,
                          bg,
                          fg,
                          controller,
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: _buildItemCard(
                            item,
                            bg,
                            fg,
                            scheme,
                            controller,
                          ),
                        ),
                        child: _buildItemCard(item, bg, fg, scheme, controller),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    SplitDragItem item,
    Color bg,
    Color fg,
    ColorScheme scheme,
    SplitScreenController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: TextStyle(color: fg, fontWeight: FontWeight.bold),
              ),
              Text(
                'x${item.quantity}',
                style: TextStyle(color: fg, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.currency}${controller.money(item.price ?? 0)} each',
                style: TextStyle(color: fg.withOpacity(0.8)),
              ),
              Text(
                '${controller.currency}${controller.money(controller.itemAmount(item))}',
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableFeedback(
    SplitDragItem item,
    Color bg,
    Color fg,
    SplitScreenController controller,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: TextStyle(color: fg, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('x${item.quantity}', style: TextStyle(color: fg)),
          ],
        ),
      ),
    );
  }

  Widget buildRightPane(
    ThemeData theme,
    ColorScheme scheme,
    bool isDark,
    SplitScreenController controller,
  ) {
    return Expanded(
      flex: controller.currentMode.value == SplitMode.items ? 2 : 1,
      child: Column(
        children: [
          _overallSummaryBar(theme, controller),
          _buildTopControls(theme, controller),
          Expanded(
  child: Obx(() {
    // Also depend on payments so UI updates when you add/remove a payment
    final _ = controller.partPayments; // register dependency

    if (controller.parts.isEmpty) {
      return Center(
        child: Text(
          controller.currentMode.value == SplitMode.items
              ? "Create parts to begin"
              : controller.currentMode.value == SplitMode.person
                  ? "Enter number of persons to split"
                  : "Enter percentages or count to split",
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: controller.parts.length,
      itemBuilder: (context, index) {
        final card = _buildPartCard(
          index,
          theme,
          scheme,
          isDark,
          controller,
        );
        if (controller.currentMode.value == SplitMode.items) {
          return DragTarget<SplitDragItem>(
            onAccept: (item) =>
                controller.onItemDroppedToPart(index, item),
            builder: (context, _, __) => card,
          );
        }
        return card;
      },
    );
  }),
),
        ],
      ),
    );
  }

  Widget _buildPartCard(
    int index,
    ThemeData theme,
    ColorScheme scheme,
    bool isDark,
    SplitScreenController controller,
  ) {
    final mode = controller.currentMode.value;
    String headerLabel;
    switch (mode) {
      case SplitMode.person:
        headerLabel = "Person ${index + 1}";
        break;
      case SplitMode.percent:
        headerLabel = "Share ${index + 1}";
        break;
      default:
        headerLabel = "Part ${index + 1}";
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartHeader(index, headerLabel, theme, controller),
          const SizedBox(height: 8),

          if (mode == SplitMode.person)
            _buildPersonModeDetails(index, theme, controller)
          else
            _buildItemModeDetails(index, theme, scheme, controller),

          if (controller.partPayments[index].isNotEmpty)
            _buildPaymentsSection(index, theme, controller),
          const SizedBox(height: 8),

          _buildPartActions(index, scheme, theme, controller),
        ],
      ),
    );
  }

 Widget _buildPartHeader(
  int index,
  String label,
  ThemeData theme,
  SplitScreenController controller,
) {
  return Obx(() => Row(
    children: [
      Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const Spacer(),
      if (controller.currentMode.value != SplitMode.person)
        Text('Items: ${controller.partItemCount(index)}', style: theme.textTheme.bodySmall),
      const SizedBox(width: 12),
      Text('Total: ${controller.currency}${controller.money(controller.partTotal(index))}', style: theme.textTheme.bodySmall),
      const SizedBox(width: 12),
      Text('Paid: ${controller.currency}${controller.money(controller.paidTotal(index))}', style: theme.textTheme.bodySmall),
      const SizedBox(width: 12),
      Text(
        'Bal: ${controller.currency}${controller.money(controller.balance(index))}',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      ),
    ],
  ));
}

  Widget _buildPersonModeDetails(
    int index,
    ThemeData theme,
    SplitScreenController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Qty: ${controller.perPersonQty(index).toStringAsFixed(2)}'),
          Text(
            'Avg Unit: ${controller.currency}${controller.money(controller.tableTotalQty > 0 ? controller.tableTotalAmount / controller.tableTotalQty : 0)}',
          ),
          Text(
            'Amount: ${controller.currency}${controller.money(controller.partTotal(index))}',
          ),
        ],
      ),
    );
  }

  Widget _buildItemModeDetails(
    int index,
    ThemeData theme,
    ColorScheme scheme,
    SplitScreenController controller,
  ) {
    final items = controller.parts[index];
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          controller.currentMode.value == SplitMode.items
              ? 'Drop items here'
              : 'Items auto-distributed',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final itemIndex = entry.key;
          final bg = _tileBg(item, scheme);
          final fg = _tileFg(item, scheme);
          return InputChip(
            backgroundColor: bg,
            labelStyle: TextStyle(color: fg, fontSize: 12),
            label: Text(
              '${item.name} x${item.quantity} • ${controller.currency}${controller.money(controller.itemAmount(item))}',
            ),
            onDeleted: controller.currentMode.value == SplitMode.items
                ? () => controller.removeItemFromPart(index, itemIndex)
                : null,
            deleteIconColor: fg,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentsSection(
    int index,
    ThemeData theme,
    SplitScreenController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payments', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: controller.partPayments[index]
              .map(
                (pay) => Chip(
                  label: Text(
                    '${pay.mop}: ${controller.currency}${controller.money(pay.amount)}',
                  ),
                  onDeleted: () => controller.removePartPayment(index, pay.id),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

 Widget _buildPartActions(
  int index,
  ColorScheme scheme,
  ThemeData theme,
  SplitScreenController controller,
) {
  return Obx(() {
    final canPay =
        controller.balance(index) > 0.01 && controller.partTotal(index) > 0;
    final canSettle = controller.canSettle(index);

    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: canPay
              ? () => _showAddPaymentSheet(index, controller)
              : null,
          icon: const Icon(Icons.add),
          label: const Text('Add Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canPay ? scheme.tertiaryContainer : scheme.surfaceVariant,
            foregroundColor: canPay
                ? scheme.onTertiaryContainer
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: canSettle
              ? () => controller.printAndSettlePart(index)
              : null,
          child: const Text("Print Bill"),
        ),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: canSettle ? () => controller.settlePart(index) : null,
          child: const Text("Settle"),
        ),
      ],
    );
  });
}

  Widget _overallSummaryBar(ThemeData theme, SplitScreenController controller) {
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Obx(
        () => Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _summaryItem(
              Icons.assignment_turned_in,
              'Assigned',
              controller.allPartsTotal,
              scheme.primary,
              controller,
            ),
            _summaryItem(
              Icons.pending_actions,
              'Remaining',
              controller.remainingLeftTotal,
              scheme.tertiary,
              controller,
            ),
            _summaryItem(
              Icons.receipt_long,
              'Table Total',
              controller.tableTotalAmount,
              scheme.secondary,
              controller,
            ),
            _summaryItem(
              Icons.payments,
              'Paid',
              controller.allPaymentsTotal,
              scheme.secondary,
              controller,
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: controller.canSettleAll()
                  ? controller.settleAllParts
                  : null,
              icon: const Icon(Icons.done_all),
              label: const Text('Settle All Parts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    IconData icon,
    String label,
    double value,
    Color color,
    SplitScreenController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text('$label: ${controller.currency}${controller.money(value)}'),
      ],
    );
  }

  Widget _buildTopControls(ThemeData theme, SplitScreenController controller) {
    switch (controller.currentMode.value) {
      case SplitMode.items:
        return _textFieldControl(
          controller.partsController,
          "Parts (drag items)",
          "e.g. 3",
          (v) => controller.createParts(int.tryParse(v) ?? 0),
        );
      case SplitMode.person:
        return _textFieldControl(
          controller.personsController,
          "Persons (equal split)",
          "e.g. 12",
          (v) =>
              controller.applyEvenPersonSplitByQty(int.tryParse(v.trim()) ?? 0),
        );
      case SplitMode.percent:
        return _textFieldControl(
          controller.percentageController,
          "Percentages or Count",
          "e.g. 25 or 4 or 50,30,20",
          (v) => v.trim().isEmpty
              ? controller.createParts(0)
              : controller.applyPercentSplitFromInput(v),
        );
    }
  }

  Widget _textFieldControl(
    TextEditingController ctrl,
    String label,
    String hint,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          labelText: label,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _showAddPaymentSheet(
    int partIndex,
    SplitScreenController controller,
  ) async {
    String selectedMop = controller.mopOptions.first;
    final amountCtrl = TextEditingController();
    final remaining = controller.balance(partIndex);

    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final viewInsets = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: viewInsets + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Payment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMop,
                  items: controller.mopOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Mode of Payment',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setSheetState(() => selectedMop = v ?? selectedMop),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText:
                        'Remaining ${controller.currency}${controller.money(remaining)}',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Use remaining balance',
                      icon: const Icon(Icons.auto_fix_high),
                      onPressed: () =>
                          amountCtrl.text = remaining.toStringAsFixed(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Add Payment'),
                    onPressed: () => controller.addPartPayment(
                      partIndex,
                      selectedMop,
                      double.tryParse(amountCtrl.text.trim()) ?? 0.0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: Theme.of(Get.context!).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}
