import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_kot.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart'; // ExtraItem
import 'package:splash_screen_03/model/entity_payment.dart';
import 'package:splash_screen_03/model/enum_bill_status.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/order/fragemnt_split.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/controller_receipt.dart';
import 'package:splash_screen_03/services/controller_server.dart';

class SplitScreenController extends GetxController with GetTickerProviderStateMixin {
  // --- Dependencies ---
  final ControllerOrder order = Get.find<ControllerOrder>();
  late final ReceiptController? receiptController = Get.isRegistered<ReceiptController>() ? Get.find<ReceiptController>() : null;
  late final ControllerServer? server = Get.isRegistered<ControllerServer>() ? Get.find<ControllerServer>() : null;

  // --- UI Controllers ---
  late TabController tabController;
  final TextEditingController partsController = TextEditingController();
  final TextEditingController personsController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();

  // --- Configuration ---
  static const bool kMoveAllQtyOnDrop = false;
  final mopOptions = const ['Cash', 'Card', 'UPI', 'Wallet', 'Other'];
  String get currency => '₹';

  // --- Reactive State ---
  final Rx<SplitMode> currentMode = SplitMode.items.obs;

  final RxList<List<SplitDragItem>> parts = <List<SplitDragItem>>[].obs;
  final RxList<List<PartPayment>> partPayments = <List<PartPayment>>[].obs;

  // Mode-specific state storage
  final Map<SplitMode, List<List<SplitDragItem>>> _modeParts = {
    SplitMode.items: [],
    SplitMode.person: [],
    SplitMode.percent: [],
  };
  final Map<SplitMode, List<List<PartPayment>>> _modePayments = {
    SplitMode.items: [],
    SplitMode.person: [],
    SplitMode.percent: [],
  };

  // --- Lifecycle ---
  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        onTabSelected(tabController.index);
      }
    });

    partsController.text = "0";
    personsController.text = "0";
    percentageController.text = "0";

    // Add a listener to reset state when the table changes
    order.rxCurrentTable.listen((_) {
      resetAllParts();
    });

    // Initial setup
    createParts(0);
    _saveCurrentModeState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      order.loadPendingTableOrders();
      if (order.rxCurrentTable.value.isEmpty && order.tableOrders.isNotEmpty) {
        final firstTable = order.tableOrders.keys.first;
        order.loadTableOrders(firstTable);
      }
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    partsController.dispose();
    personsController.dispose();
    percentageController.dispose();
    super.onClose();
  }

  // --- Computed Properties & Helpers ---
  String money(double v) => v.toStringAsFixed(2);
  double _round2(double v) => (v * 100).roundToDouble() / 100.0;
  double itemAmount(SplitDragItem i) => (i.price ?? 0) * i.quantity;

  int get personsCount {
    final txt = personsController.text.trim();
    final n = int.tryParse(txt);
    if (n != null && n > 0) return n;
    if (currentMode.value == SplitMode.person && parts.isNotEmpty) return parts.length;
    return 0;
  }

  double get tableTotalAmount => _tableTotalAmount();
  double get allPartsTotal => List.generate(parts.length, (i) => partTotal(i)).fold(0.0, (a, b) => a + b);
  double get allPaymentsTotal => List.generate(partPayments.length, (i) => paidTotal(i)).fold(0.0, (a, b) => a + b);
  int get tableTotalQty => _tableTotalQty();

  List<SplitDragItem> get availableKotItems => _buildKotDragItemsForCurrentTable();

  // --- Public Business Logic Methods ---

  void createParts(int count) {
    if (count < 0) return;
    parts.value = List.generate(count, (_) => []);
    partPayments.value = List.generate(count, (_) => []);
    _saveCurrentModeState();
  }
  
  void resetAllParts() {
    for (var mode in SplitMode.values) {
        _modeParts[mode]?.clear();
        _modePayments[mode]?.clear();
    }
    createParts(0);
    partsController.text = "0";
    personsController.text = "0";
    percentageController.text = "25";
  }

  void onTabSelected(int index) {
    final newMode = SplitMode.values[index];
    if (currentMode.value == newMode) return;

    _saveCurrentModeState();
    currentMode.value = newMode;
    _loadModeState(newMode);

    switch (newMode) {
      case SplitMode.person:
        final n = int.tryParse(personsController.text.trim()) ?? 0;
        if (n > 0) applyEvenPersonSplitByQty(n);
        break;
      case SplitMode.percent:
        if (percentageController.text.trim().isNotEmpty) {
          applyPercentSplitFromInput(percentageController.text.trim());
        }
        break;
      case SplitMode.items:
        // No special action needed
        break;
    }
  }

  void onItemDroppedToPart(int partIndex, SplitDragItem item) {
    if (currentMode.value != SplitMode.items || item.quantity <= 0) return;

    final int qtyToAdd = kMoveAllQtyOnDrop ? item.quantity : 1;

    final part = parts[partIndex];
    final idx = part.indexWhere((e) => e.id == item.id);

    if (idx >= 0) {
      final existing = part[idx];
      part[idx] = existing.copyWith(quantity: existing.quantity + qtyToAdd);
    } else {
      part.add(item.copyWith(quantity: qtyToAdd));
    }
    parts.refresh();
    _saveCurrentModeState();
  }

  void removeItemFromPart(int partIndex, int itemIndex) {
    if (currentMode.value != SplitMode.items) return;
    parts[partIndex].removeAt(itemIndex);
    parts.refresh();
    _saveCurrentModeState();
  }

  void addPartPayment(int partIndex, String mop, double amount) {
    if (amount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a positive amount.');
      return;
    }
    final remaining = balance(partIndex);
    if (amount - remaining > 0.01) {
      Get.snackbar('Amount Exceeds Balance', 'The payment amount is more than the remaining balance.');
      return;
    }

    partPayments[partIndex].add(PartPayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mop: mop,
      amount: amount,
    ));
    partPayments.refresh();
    _saveCurrentModeState();
    Get.back(); // Close the bottom sheet
  }

  void removePartPayment(int partIndex, String paymentId) {
    partPayments[partIndex].removeWhere((p) => p.id == paymentId);
    partPayments.refresh();
    _saveCurrentModeState();
  }

  Future<void> settlePart(int index, {bool askConfirm = true, bool removeSlotAfterSettle = true}) async {
    if (!canSettle(index)) {
      Get.snackbar('Cannot Settle', 'Part is not fully paid or is empty.');
      return;
    }

    bool confirmed = !askConfirm;
    if (askConfirm) {
      confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Settle Part'),
              content: Text('Settle this part for $currency${money(partTotal(index))}?'),
              actions: [
                TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Get.back(result: true), child: const Text('Confirm')),
              ],
            ),
          ) ?? false;
    }

    if (!confirmed) return;

    await _performSettlement(index, removeSlotAfterSettle: removeSlotAfterSettle, showSnack: true);
  }

  Future<void> settleAllParts() async {
    if (!canSettleAll()) {
      Get.snackbar('Not Ready', 'One or more parts are not fully paid.');
      return;
    }

    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Settle All Parts'),
            content: Text('Settle all payable parts now? Total: $currency${money(allPartsTotal)}'),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Get.back(result: true), child: const Text('Confirm')),
            ],
          ),
        ) ?? false;

    if (!confirmed) return;

    final indicesToSettle = <int>[];
    if (currentMode.value == SplitMode.person) {
      indicesToSettle.addAll(List.generate(parts.length, (i) => i));
    } else {
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) indicesToSettle.add(i);
      }
    }

    for (final idx in indicesToSettle) {
      if (canSettle(idx)) {
        await _performSettlement(idx, removeSlotAfterSettle: false, showSnack: false);
      } else {
        Get.snackbar('Skipped', 'Part ${idx + 1} was not ready and was skipped.');
      }
    }

    Get.snackbar('Finished', 'All payable parts have been settled.');
    _postSettleRefresh();
  }

  Future<void> printAndSettlePart(int index) async {
    if (!canSettle(index)) {
      Get.snackbar('Not Paid', 'Please add payments to settle this part before printing.');
      return;
    }

    final bill = await _performSettlement(index, showSnack: false);
    if (bill == null) {
      Get.snackbar('Error', 'Could not create bill for printing.');
      return;
    }

    final parent = _findActiveBookedBillForCurrentTable();
    if (parent == null || parent.listFood.isEmpty) {
      Get.snackbar('Missing KOT', 'No KOT found for this table to print from.');
      return;
    }
    final EntityOrderFood latestKot = parent.listFood.last;

    final groupedItems = _groupedItemsForBill(bill);

    try {
      // Uncomment and use your actual printing logic
      // await billPrintByConfigType(
      //   "BILL",
      //   kot: latestKot,
      //   bill: bill,
      //   groupedItems: groupedItems,
      // );
      Get.snackbar('Printed', 'Bill #${bill.orderNumber} sent to printer.');
    } catch (e) {
      Get.snackbar('Print Failed', 'Error: ${e.toString()}');
    }
  }

  void navigateHome() => Get.offAllNamed('/home');

  // --- Calculation & State Logic (mostly private) ---

  double partTotal(int index) {
    if (index >= parts.length) return 0.0;
    if (currentMode.value == SplitMode.person) return _perPersonAmount(index);
    return parts[index].fold<double>(0.0, (sum, it) => sum + itemAmount(it));
  }

  double paidTotal(int index) => index >= partPayments.length ? 0.0 : partPayments[index].fold<double>(0.0, (sum, p) => sum + p.amount);
  double balance(int index) => (partTotal(index) - paidTotal(index)).clamp(0, double.infinity);
  int partItemCount(int index) => index >= parts.length ? 0 : parts[index].fold<int>(0, (sum, it) => sum + it.quantity);
bool canSettle(int index) {
  if (index >= parts.length || index >= partPayments.length) return false;
  final total = partTotal(index);
  if (total <= 0) return false;
  if (currentMode.value == SplitMode.person) {
    return balance(index) <= 0.01; // was abs() < 0.01
  }
  return parts[index].isNotEmpty && balance(index) <= 0.01;
}

  bool canSettleAll() {
    if (parts.isEmpty) return false;
    int validParts = 0;
    for (int i = 0; i < parts.length; i++) {
      if (currentMode.value != SplitMode.person && parts[i].isEmpty) continue;
      if (partTotal(i) <= 0) continue;
      if (!canSettle(i)) return false;
      validParts++;
    }
    return validParts > 0;
  }

  double get remainingLeftTotal {
    final leftItems = availableKotItems;
    return leftItems.fold<double>(0.0, (sum, it) => sum + (it.price ?? 0) * (it.quantity));
  }

  // --- Auto-Splitting Logic ---

  void applyEvenPersonSplitByQty(int count) {
    if (count <= 0) {
      createParts(0);
      return;
    }

    final all = _buildAllKotItemsForCurrentTable();
    final result = List.generate(count, (_) => <SplitDragItem>[]);
    int nextIdx = 0; // Fair distribution of remainders

    for (final it in all) {
      if (it.quantity <= 0) continue;
      final base = it.quantity ~/ count;
      final rem = it.quantity % count;

      for (var p = 0; p < count; p++) {
        if (base > 0) _addToPart(result[p], it, base);
      }
      for (var r = 0; r < rem; r++) {
        final p = (nextIdx + r) % count;
        _addToPart(result[p], it, 1);
      }
      nextIdx = (nextIdx + rem) % count;
    }
    parts.value = result;
    partPayments.value = List.generate(count, (_) => <PartPayment>[]);
    _saveCurrentModeState();
  }

  void applyPercentSplitFromInput(String input) {
    final raw = input.replaceAll('%', '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    List<double> percents = [];

    if (raw.isEmpty) percents = [100];
    else if (raw.length == 1) {
      final singleInt = int.tryParse(raw.first);
      final singleDbl = double.tryParse(raw.first) ?? 0;
      if (singleInt != null && singleInt >= 2 && singleInt <= 20) {
        percents = List.filled(singleInt, 100.0 / singleInt);
      } else if (singleDbl > 0 && (100 % singleDbl == 0)) {
        percents = List.filled((100 / singleDbl).round(), singleDbl);
      } else if (singleDbl > 0 && singleDbl < 100) {
        percents = [singleDbl, 100 - singleDbl];
      } else {
        percents = [100];
      }
    } else {
      percents = raw.map((s) => double.tryParse(s) ?? 0).toList();
    }

    percents = percents.where((p) => p > 0).toList();
    if (percents.isEmpty) {
      Get.snackbar('Invalid Input', 'Enter valid percentage values or a count.');
      createParts(0);
      return;
    }
    _applyPercentSplit(percents);
  }

  // --- Private Helper Methods ---

  void _saveCurrentModeState() {
    _modeParts[currentMode.value] = parts.map((l) => l.toList()).toList();
    _modePayments[currentMode.value] = partPayments.map((l) => l.toList()).toList();
  }

  void _loadModeState(SplitMode mode) {
    parts.value = (_modeParts[mode] ?? []).map((l) => l.toList()).toList();
    partPayments.value = (_modePayments[mode] ?? []).map((l) => l.toList()).toList();
  }

  void _postSettleRefresh() {
    order.loadPendingTableOrders();
    // Force a re-evaluation of available items and parts
    parts.refresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasTables = order.tableOrders.isNotEmpty;
      final leftItemsEmpty = availableKotItems.isEmpty;
      final allPartsEmpty = parts.every((p) => p.isEmpty);
      
      if (!hasTables || (leftItemsEmpty && allPartsEmpty)) {
          // If everything is settled, we can clear the screen
          resetAllParts();
          Get.snackbar("Table Cleared", "All items for this table have been settled.");
      }
    });
  }
  
  // REPLACE this function
  List<SplitDragItem> _buildKotDragItemsForCurrentTable() {
    // 1. Get the completely up-to-date list of all available items.
    final allAvailableItems = _buildAllKotItemsForCurrentTable();

    // 2. Calculate how many of each item are already assigned to split parts on the screen.
    final Map<String, int> assignedQty = {};
    for (final part in parts) {
      for (final item in part) {
        assignedQty[item.id] = (assignedQty[item.id] ?? 0) + item.quantity;
      }
    }

    // 3. Create the final list for the UI by subtracting assigned quantities.
    final List<SplitDragItem> remainingItemsForUi = [];
    for (final item in allAvailableItems) {
      final int remain = item.quantity - (assignedQty[item.id] ?? 0);
      if (remain > 0) {
        // Only add items to the list if there's a quantity left to be dragged.
        remainingItemsForUi.add(item.copyWith(quantity: remain));
      }
    }

    return remainingItemsForUi;
  }

  // REPLACE this function
  List<SplitDragItem> _buildAllKotItemsForCurrentTable() {
    final tableName = order.rxCurrentTable.value;
    final activeBill = order.findLatestOpenBillForTable(tableName);

    // If there's no active bill with KOTs, there are no items to split.
    if (activeBill == null || activeBill.listFood.isEmpty) {
      return [];
    }

    // This map will aggregate items from all KOTs for the current bill.
    final Map<String, SplitDragItem> aggregatedItems = {};

    // Create a quick lookup map for food details to avoid repeated DB lookups
    final allDbFoods = order.boxEntityFood.getAll();
    final Map<int, EntityFood> foodMapById = {
      for (var f in allDbFoods) (f.foodId ?? 0): f
    };

    // Iterate over each KOT (EntityOrderFood) associated with the bill
    for (final kot in activeBill.listFood) {
      // The itemsJson field holds the most up-to-date state of items (qty, settled status)
      if ((kot.itemsJson ?? '').isEmpty) continue;

      try {
        final decoded = jsonDecode(kot.itemsJson!);
        final rawItems = (decoded['items'] as List?) ?? [];

        for (final itemData in rawItems) {
          final isSettled = itemData['status'] == true;
          final qty = (itemData['qty'] as num?)?.toInt() ?? 0;

          // CRITICAL: Skip items that are already fully settled or have no quantity
          if (isSettled || qty <= 0) {
            continue;
          }

          final bool isExtra = itemData['extra'] == true;
          final String name = (itemData['name'] ?? '').toString();
          final double price = (itemData['price'] as num?)?.toDouble() ?? 0.0;
          final int foodId = (itemData['id'] as num?)?.toInt() ?? 0;
          
          // Create a unique ID for aggregation (e.g., 'f:12' for food, 'x:coke' for extra)
          final String uniqueId = isExtra ? 'x:$name' : 'f:$foodId';

          if (aggregatedItems.containsKey(uniqueId)) {
            // If item already exists in our map, just add the quantity
            final existing = aggregatedItems[uniqueId]!;
            aggregatedItems[uniqueId] =
                existing.copyWith(quantity: existing.quantity + qty);
          } else {
            // If it's a new item, create the full SplitDragItem object
            aggregatedItems[uniqueId] = SplitDragItem(
              id: uniqueId,
              name: name,
              quantity: qty,
              isExtra: isExtra,
              price: price,
              food: isExtra ? null : foodMapById[foodId], // Look up food details
              extra: isExtra
                  ? ExtraItem(name: name, qty: qty, price: price, id: "0")
                  : null,
            );
          }
        }
      } catch (e) {
        debugPrint("Error parsing KOT itemsJson in split screen: $e");
      }
    }

    // Return the final list of aggregated, available items.
    return aggregatedItems.values.toList();
  }

  // REPLACE this function
  double _tableTotalAmount() {
    // Get the complete and accurate list of all available items.
    final all = _buildAllKotItemsForCurrentTable();
    
    // Calculate the total amount based on this correct list.
    return all.fold<double>(0.0, (sum, it) => sum + (it.price ?? 0) * it.quantity);
  }

  int _tableTotalQty() => _buildAllKotItemsForCurrentTable().fold<int>(0, (s, it) => s + it.quantity);

  double _avgUnitPriceForCurrentTable() {
    final qty = _tableTotalQty().toDouble();
    return (qty <= 0) ? 0.0 : _tableTotalAmount() / qty;
  }

  double _perPersonAmount(int index) {
    if (personsCount <= 0) return 0.0;
    final total = _tableTotalAmount();
    final per = _round2(total / personsCount);
    // last share = total - sum(previous) to avoid rounding errors
    return (index == personsCount - 1) ? _round2(total - per * (personsCount - 1)) : per;
  }

  double perPersonQty(int index) {
    if (personsCount <= 0) return 0.0;
    final totalQty = _tableTotalQty().toDouble();
    final per = _round2(totalQty / personsCount);
    return (index == personsCount - 1) ? _round2(totalQty - per * (personsCount - 1)) : per;
  }

  void _applyPercentSplit(List<double> percents) {
    final count = percents.length;
    final all = _buildAllKotItemsForCurrentTable();
    final result = List.generate(count, (_) => <SplitDragItem>[]);

    final weights = _allocateQtyByWeights(100, percents); // Get integer weights

    for (final it in all) {
      final shares = _allocateQtyByWeights(it.quantity, weights.map((e) => e.toDouble()).toList());
      for (int i = 0; i < count; i++) {
        if (shares[i] > 0) _addToPart(result[i], it, shares[i]);
      }
    }
    parts.value = result;
    partPayments.value = List.generate(count, (_) => <PartPayment>[]);
    _saveCurrentModeState();
  }

  void _addToPart(List<SplitDragItem> part, SplitDragItem item, int qty) {
    if (qty <= 0) return;
    final idx = part.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      final existing = part[idx];
      part[idx] = existing.copyWith(quantity: existing.quantity + qty);
    } else {
      part.add(item.copyWith(quantity: qty));
    }
  }

  List<int> _allocateQtyByWeights(int qty, List<double> weights) {
    final n = weights.length;
    if (qty <= 0 || n == 0) return List.filled(n, 0);
    final sumW = weights.fold<double>(0.0, (a, b) => a + (b.isNegative ? 0 : b));
    if (sumW <= 0) return List.filled(n, 0);

    final raw = weights.map((w) => (qty * (w.isNegative ? 0 : w) / sumW)).toList();
    final floors = raw.map((r) => r.floor()).toList();
    int used = floors.fold(0, (a, b) => a + b);
    int left = qty - used;

    final indexedFrac = List.generate(n, (i) => MapEntry(i, raw[i] - floors[i]))
      ..sort((a, b) => b.value.compareTo(a.value));
    int k = 0;
    while (left > 0 && indexedFrac.isNotEmpty) {
      floors[indexedFrac[k].key] += 1;
      left -= 1;
      k = (k + 1) % indexedFrac.length;
    }
    return floors;
  }
  
  // --- Settlement & Persistence Logic (very complex, keep private) ---
  // ... (All settlement related methods from the original file, now private)

    Future<EntityOrder?> _performSettlement(int index, { bool showSnack = true, bool removeSlotAfterSettle = true }) async {
    final itemsToSettle = parts[index];
    final parentBill = _findActiveBookedBillForCurrentTable();

    final newBill = await _createAndSavePartBill(
      partIndex: index,
      items: itemsToSettle,
      payments: partPayments[index],
      parentBill: parentBill,
    );

    if (parentBill != null) {
      final Map<String, int> settleMap = {};
      for (final it in itemsToSettle) {
        settleMap[it.id] = (settleMap[it.id] ?? 0) + it.quantity;
      }
      await _applySettlementToParentKots(parentBill: parentBill, settleMap: settleMap);
    }

    // --- State Update ---
    parts[index].clear();
    partPayments[index].clear();

    if (currentMode.value == SplitMode.person && removeSlotAfterSettle) {
      parts.removeAt(index);
      partPayments.removeAt(index);
      personsController.text = parts.length.toString();
    }
    parts.refresh(); // Crucial for GetX to detect list-of-list change

    if (showSnack) {
      Get.snackbar('Settled', '${currentMode.value == SplitMode.person ? "Person" : "Part"} ${index + 1} settled. Bill #${newBill?.orderNumber ?? ""}');
    }

    _postSettleRefresh();
    _saveCurrentModeState();

    return newBill;
  }
Future<EntityOrder?> _createAndSavePartBill({
  required int partIndex,
  required List<SplitDragItem> items,
  required List<PartPayment> payments,
  required EntityOrder? parentBill,
}) async {
  // Merge same items (by id)
  final Map<String, SplitDragItem> merged = {};
  for (final it in items) {
    if (!merged.containsKey(it.id)) {
      merged[it.id] = it;
    } else {
      final prev = merged[it.id]!;
      merged[it.id] = prev.copyWith(quantity: prev.quantity + it.quantity);
    }
  }
  final mergedItems = merged.values.toList();

  // Build bill items
  final List<Map<String, dynamic>> itemsForBill = [];
  double totalAmount = 0.0;

  if (currentMode.value == SplitMode.person) {
    final double avgUnit = _avgUnitPriceForCurrentTable();
    final double shareAmount = _perPersonAmount(partIndex);
    final double qtyForBill =
        avgUnit > 0 ? _round2(shareAmount / avgUnit) : perPersonQty(partIndex);

    totalAmount = shareAmount;
    itemsForBill.add({
      'id': 0,
      'name': 'Person ${partIndex + 1} Share',
      'qty': qtyForBill,
      'price': avgUnit,
      'amount': totalAmount,
      'extra': true,
    });
  } else {
    for (final it in mergedItems) {
      final price = (it.price ?? 0.0);
      final amt = price * it.quantity;
      totalAmount += amt;
      if (it.isExtra) {
        itemsForBill.add({
          'id': 0,
          'name': it.name,
          'qty': it.quantity,
          'price': price,
          'amount': amt,
          'extra': true,
        });
      } else {
        itemsForBill.add({
          'id': it.food?.foodId ?? 0,
          'name': it.food?.foodName ?? it.name,
          'qty': it.quantity,
          'price': price,
          'amount': amt,
        });
      }
    }
  }

  final String paymentMode =
      payments.isEmpty ? 'Unknown' : (payments.length == 1 ? payments.first.mop : 'Mixed');
  final nowIso = DateTime.now().toUtc().toIso8601String();
  final nextorderNumber = await order.controllerSetting.acquireNextorderNumber();

  final tbl = order.rxCurrentTable.value;
  final partLabel = currentMode.value == SplitMode.person
      ? "Person ${partIndex + 1}"
      : currentMode.value == SplitMode.percent
          ? "Share ${partIndex + 1}"
          : "Part ${partIndex + 1}";

  final bill = EntityOrder(
    orderNumber: nextorderNumber,
    startTime: nowIso,
    endTime: nowIso,
    tableName: tbl.isNotEmpty ? "$tbl - $partLabel" : partLabel,
    tableSeat: 0,
    orderTypeId: parentBill?.orderTypeId ?? 'Dine-In',
    userName: parentBill?.userName ?? "",
    createdOn: nowIso,
    status: BillStatus.settled.value,
    totalAmount: totalAmount,
  );

  _ensureBillHasUuid(bill);

  // Store the split detail as JSON if your EntityOrder has itemsJson
  final wrapper = {
    'meta': {
      'splitOforderNumber': parentBill?.orderNumber,
      'splitOfBillUuid': _readBillUuid(parentBill ?? bill),
      'tableOriginal': parentBill?.tableName ?? order.rxCurrentTable.value,
      'partIndex': partIndex + 1,
      'payments': payments.map((e) => e.toJson()).toList(),
      'paymentMode': paymentMode,
      'mode': currentMode.value.name,
      if (currentMode.value == SplitMode.person)
        ...{
          'pricing': 'equal_amount_by_person',
          'personsCount': personsCount,
          'avgUnitPrice': _avgUnitPriceForCurrentTable(),
          'shareQty': perPersonQty(partIndex),
          'shareAmount': _perPersonAmount(partIndex),
        },
    },
    'items': itemsForBill,
  };
  try {
    (bill as dynamic).itemsJson = jsonEncode(wrapper);
  } catch (_) {
    // itemsJson not present on EntityOrder; ignore
  }

  // DO NOT set orderItems if your model doesn't have it
  // try to set optional fields only if they exist
  final intQtyForDb = (currentMode.value == SplitMode.person)
      ? 0
      : itemsForBill.fold<int>(
          0,
          (p, e) =>
              p +
              ((e['qty'] is num)
                  ? (e['qty'] as num).toInt()
                  : int.tryParse(e['qty'].toString()) ?? 0),
        );

  try {
    (bill as dynamic).totalQty = intQtyForDb;
  } catch (_) {}
  try {
    (bill as dynamic).billDate = nowIso;
  } catch (_) {}
  try {
    final dyn = bill as dynamic;
    if ((dyn.createdAt as String?) == null || (dyn.createdAt as String?)!.isEmpty) {
      dyn.createdAt = nowIso;
    }
  } catch (_) {}

  bill.orderId = order.boxEntityOrder.put(bill);
  await _savePaymentsForBill(bill, payments);

  receiptController?.fetchFromBills(page: (receiptController?.currentPage.value ?? 1));

  if (server != null) {
    server!.messages.add(
        "💰 Split Bill Settled ➜ Bill #${bill.orderNumber} ($partLabel of table ${order.rxCurrentTable.value}) (uuid:${_readBillUuid(bill) ?? '-'})");
    server!.broadcastBillSettled({
      "orderNumber": bill.orderNumber,
      "billUuid": _readBillUuid(bill),
      "tableName": bill.tableName,
      "total": totalAmount,
      "paymentMode": paymentMode,
      "settledBy": "server"
    });
  }
  return bill;
}
  // All other private helpers from the original file (_applySettlementToParentKots, _findActiveBookedBillForCurrentTable, etc.) go here.
  // ... (They are mostly internal logic and are kept as is)
  Future<void> _applySettlementToParentKots({ required EntityOrder parentBill, required Map<String, int> settleMap }) async { if (settleMap.isEmpty) return; final kots = List<EntityOrderFood>.from(parentBill.listFood); kots.sort((a, b) => (a.createdOn ?? '').compareTo(b.createdOn ?? '')); final remainingToSettle = Map<String, int>.from(settleMap); for (final kot in kots) { if (remainingToSettle.isEmpty) break; if (kot.itemsJson == null) continue; final decoded = jsonDecode(kot.itemsJson!); final rawItems = (decoded['items'] as List?) ?? []; bool changed = false; for (final item in rawItems) { final isSettled = item['status'] == true; if (isSettled == true) continue; final isExtra = item['extra'] == true; final name = (item['name'] ?? '').toString(); final rawId = (item['id'] ?? 0) as int; final key = isExtra ? 'x:$name' : 'f:$rawId'; final need = remainingToSettle[key] ?? 0; if (need <= 0) continue; final qty = (item['qty'] ?? 0) as int; if (qty <= 0) { item['status'] = true; changed = true; continue; } final reduce = need >= qty ? qty : need; final newQty = qty - reduce; item['qty'] = newQty; final price = (item['price'] ?? 0.0).toDouble(); item['amount'] = price * newQty; if (newQty <= 0) { item['status'] = true; } remainingToSettle[key] = need - reduce; changed = true; if ((remainingToSettle[key] ?? 0) <= 0) { remainingToSettle.remove(key); } if (remainingToSettle.isEmpty) break; } if (changed) { try { decoded['items'] = rawItems; kot.itemsJson = jsonEncode(decoded); try { order.boxEntityOrderFood.put(kot); } catch (_) {} } catch (_) {} } } try { order.boxEntityOrder.put(parentBill); } catch (_) {} bool anyUnsettled = false; for (final k in parentBill.listFood) { if (k.itemsJson == null) continue; final dec = jsonDecode(k.itemsJson!); final itms = (dec['items'] as List?) ?? []; for (final it in itms) { final settled = it['status'] == true; final qty = (it['qty'] ?? 0) as int; if (!settled && qty > 0) { anyUnsettled = true; break; } } if (anyUnsettled) break; } if (!anyUnsettled) { parentBill.status = BillStatus.settled.value; try { order.boxEntityOrder.put(parentBill); } catch (_) {} } }
  EntityOrder? _findActiveBookedBillForCurrentTable() { final t = order.rxCurrentTable.value; if (t.isEmpty) return null; final bills = order.boxEntityOrder.getAll(); final matches = bills.where((b) => (b.tableName ?? '') == t && b.status == BillStatus.booked.value).toList(); if (matches.isEmpty) return null; matches.sort((a, b) => (b.createdOn ?? '').compareTo(a.createdOn ?? '')); return matches.first; }
  void _ensureBillHasUuid(EntityOrder bill) { try { final dynamic dyn = bill as dynamic; String? existing; try { existing = dyn.uuid as String?; } catch (_) { try { existing = dyn.billUuid as String?; } catch (_) { existing = null; } } if (existing == null || existing.isEmpty) { final newUuid = DateTime.now().microsecondsSinceEpoch.toString(); try { dyn.uuid = newUuid; } catch (_) { try { dyn.billUuid = newUuid; } catch (_) {} } } } catch (_) {} }
  String? _readBillUuid(EntityOrder bill) { try { final dynamic d = bill as dynamic; if (d.uuid is String && (d.uuid as String).isNotEmpty) return d.uuid; if (d.billUuid is String && (d.billUuid as String).isNotEmpty) { return d.billUuid; } } catch (_) {} return null; }
  Future<void> _savePaymentsForBill(EntityOrder bill, List<PartPayment> parts) async { if (parts.isEmpty) return; final payEntities = parts.map((p) => Payment(price: p.amount, mode: p.mop)).toList(); order.boxPayment.putMany(payEntities); final savedBill = order.boxEntityOrder.get(bill.orderId); if (savedBill != null) { savedBill.payments.addAll(payEntities); order.boxEntityOrder.put(savedBill); } else { bill.payments.addAll(payEntities); order.boxEntityOrder.put(bill); } }
  Map<String, List<MapEntry<dynamic, int>>> _groupedItemsForBill(EntityOrder bill) { final items = _itemsFromBillForPrint(bill); final tableName = order.rxCurrentTable.value; final data = order.tableOrders[tableName]; final Map<int, EntityFood> foodById = {}; final Map<String, ExtraItem> extraByName = {}; if (data != null) { for (final f in data.orderItems.keys) { foodById[f.foodId ?? 0] = f; } for (final ex in data.extraItems) { extraByName[ex.name] = ex; } } final entries = <MapEntry<dynamic, int>>[]; for (final it in items) { final qtyD = (it['qty'] is num) ? (it['qty'] as num).toDouble() : double.tryParse(it['qty']?.toString() ?? '0') ?? 0.0; final qty = qtyD.round(); if (qty <= 0) continue; final name = (it['name'] ?? '').toString(); final double price = (it['price'] is int) ? (it['price'] as int).toDouble() : (it['price'] ?? 0.0) as double; dynamic keyObj; if (it['extra'] == true) { keyObj = extraByName[name] ?? ExtraItem(name: name, qty: qty, price: price, id: "0"); } else { final int fid = (it['id'] ?? 0) as int; final EntityFood? food = foodById[fid]; keyObj = food ?? ExtraItem(name: name, qty: qty, price: price, id: "fid"); } entries.add(MapEntry<dynamic, int>(keyObj, qty)); } return {'BILL': entries}; }
  List<Map<String, dynamic>> _itemsFromBillForPrint(EntityOrder bill) { try { final dyn = bill as dynamic; final j = dyn.itemsJson as String?; if (j != null && j.isNotEmpty) { final d = jsonDecode(j); final raw = (d['items'] as List?) ?? []; return raw.map<Map<String, dynamic>>((e) { final qtyVal = e['qty']; return {'id': e['id'] ?? 0, 'name': (e['name'] ?? '').toString(), 'qty': qtyVal is num ? qtyVal.toDouble() : double.tryParse(qtyVal?.toString() ?? '0') ?? 0.0, 'price': (e['price'] is int) ? (e['price'] as int).toDouble() : (e['price'] ?? 0.0) as double, 'amount': (e['amount'] is int) ? (e['amount'] as int).toDouble() : (e['amount'] ?? 0.0) as double, 'extra': e['extra'] == true, }; }).toList(); } final oi = (dyn.orderItems as List?) ?? []; return oi.map<Map<String, dynamic>>((e) { final qtyVal = e['qty']; return {'id': e['id'] ?? 0, 'name': (e['name'] ?? '').toString(), 'qty': qtyVal is num ? qtyVal.toDouble() : double.tryParse(qtyVal?.toString() ?? '0') ?? 0.0, 'price': (e['price'] is int) ? (e['price'] as int).toDouble() : (e['price'] ?? 0.0) as double, 'amount': (e['amount'] is int) ? (e['amount'] as int).toDouble() : (e['amount'] ?? 0.0) as double, 'extra': e['extra'] == true, }; }).toList(); } catch (_) { return []; } }
}